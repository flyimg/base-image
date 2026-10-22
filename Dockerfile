FROM php:8.3-fpm-bookworm AS base

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION=3.2.3.2

# Base deps and tools. xz-utils is required to extract s6-overlay.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg2 ca-certificates lsb-release software-properties-common \
    git make pkg-config autoconf cmake clang automake yasm \
    libtool zip unzip cron wget python3-dev python3-distutils python3-opencv python3-pip libssl-dev \
    libpng-dev libjpeg62-turbo-dev libtiff-dev libgif-dev \
    libxml2-dev libfreetype6-dev libfontconfig1-dev liblcms2-dev \
    libxext6 libgomp1 libbrotli-dev libyaml-dev libtcmalloc-minimal4 \
    libsdl1.2-dev ghostscript ffmpeg opencv-data \
    libde265-0 libde265-dev x265 libx265-dev \
    nginx webp libpng16-16 liblcms2-2 libxml2-utils fonts-dejavu xz-utils && \
    rm -rf /var/lib/apt/lists/*

# s6-overlay v3. The v1 tarball ships a real /bin directory, which replaces
# Bookworm's /bin -> /usr/bin symlink and removes /bin/sh.
# symlinks-noarch keeps /usr/bin/with-contenv for the php-fpm service script.
RUN ARCH="$(case "$TARGETPLATFORM" in \
        "linux/amd64") echo "x86_64" ;; \
        "linux/arm/v7") echo "arm" ;; \
        "linux/arm/v8"|"linux/arm64") echo "aarch64" ;; \
        *) echo "x86_64" ;; \
    esac)" && \
    curl -sSL -o /tmp/s6-overlay-noarch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
    curl -sSL -o /tmp/s6-overlay-arch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz" && \
    curl -sSL -o /tmp/s6-overlay-symlinks-noarch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
    rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-arch.tar.xz /tmp/s6-overlay-symlinks-noarch.tar.xz

##########################################
# Builder for native libs
##########################################
FROM base AS builder

ARG LIB_JXL_VERSION=0.12.0
ARG LIB_WEBP_VERSION=1.6.0
ARG LIB_AOM_VERSION=3.15.2
ARG LIB_HEIF_VERSION=1.23.6
ARG MOZJPEG_VERSION=4.1.5

WORKDIR /build

# Build libjxl against system brotli. The bundled brotli installs a newer
# libbrotlidec into /usr/local that then fails to link against Bookworm's
# libbrotlicommon when building libheif tools on ARM.
RUN git clone -b v${LIB_JXL_VERSION} --depth 1 --recursive https://github.com/libjxl/libjxl.git && \
    mkdir libjxl/build && cd libjxl/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DJPEGXL_FORCE_SYSTEM_BROTLI=ON .. && \
    make -j$(nproc) && make install && ldconfig && cd ../.. && rm -rf libjxl

# Build libwebp
RUN git clone -b v${LIB_WEBP_VERSION} --depth 1 https://chromium.googlesource.com/webm/libwebp && \
    cd libwebp && ./autogen.sh && ./configure && make -j$(nproc) && make install && cd .. && rm -rf libwebp

# Build libaom
RUN git clone -b v${LIB_AOM_VERSION} --depth 1 https://aomedia.googlesource.com/aom && \
    mkdir build_aom && cd build_aom && \
    cmake ../aom/ -DAOM_TARGET_CPU=generic -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && \
    make -j$(nproc) && make install && ldconfig && cd .. && rm -rf aom build_aom

# Build libheif. Skip examples/tests; they are unused in this image and were
# the link site for the brotli mismatch above.
RUN curl -L -o libheif.tar.gz https://github.com/strukturag/libheif/releases/download/v${LIB_HEIF_VERSION}/libheif-${LIB_HEIF_VERSION}.tar.gz && \
    tar xzf libheif.tar.gz && cd libheif-${LIB_HEIF_VERSION} && \
    mkdir build && cd build && \
    cmake --preset=release -DWITH_EXAMPLES=OFF -DBUILD_TESTING=OFF -DWITH_GDK_PIXBUF=OFF .. && \
    make -j$(nproc) && make install && ldconfig && cd ../.. && rm -rf libheif-${LIB_HEIF_VERSION} libheif.tar.gz

# Build MozJPEG into /opt/mozjpeg so it does not replace system libjpeg.
# Static cjpeg avoids a competing libjpeg.so on the loader path.
# cmake's default prefix is /opt/mozjpeg; make install places cjpeg in bin/.
RUN wget https://github.com/mozilla/mozjpeg/archive/refs/tags/v${MOZJPEG_VERSION}.tar.gz && \
    tar xzf v${MOZJPEG_VERSION}.tar.gz && cd mozjpeg-${MOZJPEG_VERSION} && \
    cmake -DCMAKE_INSTALL_PREFIX=/opt/mozjpeg -DENABLE_SHARED=OFF . && \
    make -j$(nproc) && make install && cd .. && rm -rf mozjpeg-${MOZJPEG_VERSION} v${MOZJPEG_VERSION}.tar.gz

##########################################
# Final Image
##########################################
FROM base AS final

COPY --from=builder /usr/local /usr/local
# MozJPEG installs under /opt/mozjpeg, which is outside the /usr/local copy above.
COPY --from=builder /opt/mozjpeg /opt/mozjpeg

# Install ImageMagick
ARG IM_VERSION=7.1.2-34
RUN git clone -b ${IM_VERSION} --depth 1 https://github.com/ImageMagick/ImageMagick.git && \
    cd ImageMagick && ./configure --without-magick-plus-plus --disable-docs --disable-static \
    --with-tiff --with-jxl --with-tcmalloc && make -j$(nproc) && make install && ldconfig && cd .. && rm -rf ImageMagick

# PHP Extensions
RUN docker-php-ext-install opcache && \
    pecl install yaml xdebug && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini && \
    echo "zend_extension=xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/xdebug.ini

# Python deps. Bookworm marks the system interpreter as externally managed,
# so pip refuses to install unless this override is set.
ARG PILLOW_VERSION=11.3.0
ARG PILLOW_AVIF_PLUGIN_VERSION=1.6.0
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir numpy pillow==${PILLOW_VERSION} && \
    if [ "$TARGETPLATFORM" = "linux/amd64" -o "$TARGETPLATFORM" = "linux/arm64" ]; then \
        pip3 install --no-cache-dir pillow-avif-plugin==${PILLOW_AVIF_PLUGIN_VERSION}; \
    fi

# To creates the necessary links and cache in /usr/local/lib
RUN ldconfig /usr/local/lib && ln -sf /opt/mozjpeg/bin/cjpeg /usr/local/bin/cjpeg

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy configs
COPY resources/etc/ /etc/
COPY resources/php-fpm.d/ /usr/local/etc/php-fpm.d/
COPY resources/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

RUN rm -f /etc/nginx/conf.d/default.conf || true

ENV PORT=80
WORKDIR /var/www/html
ENTRYPOINT ["docker-entrypoint", "/init"]
