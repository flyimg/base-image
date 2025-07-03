FROM php:8.3-fpm-bullseye AS base

ENV DEBIAN_FRONTEND=noninteractive

ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION=1.22.1.0

# Determine architecture for s6-overlay
RUN ARCH="$(case "$TARGETPLATFORM" in \
        "linux/amd64") echo "amd64" ;; \
        "linux/arm/v7") echo "arm" ;; \
        "linux/arm/v8"|"linux/arm64") echo "aarch64" ;; \
        *) echo "amd64" ;; \
    esac)" && \
    curl -sSL -o /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.gz && \
    tar xzf /tmp/s6-overlay.tar.gz -C / && \
    rm /tmp/s6-overlay.tar.gz

# Base deps and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg2 ca-certificates lsb-release software-properties-common \
    git make pkg-config autoconf cmake clang automake yasm \
    libtool zip unzip cron wget python3-dev python3-distutils python3-opencv python3-pip libssl-dev \
    libpng-dev libjpeg62-turbo-dev libtiff-dev libgif-dev \
    libxml2-dev libfreetype6-dev libfontconfig1-dev liblcms2-dev \
    libxext6 libgomp1 libbrotli-dev libyaml-dev libtcmalloc-minimal4 \
    libsdl1.2-dev ghostscript ffmpeg opencv-data \
    libde265-0 libde265-dev x265 libx265-dev \
    nginx webp libpng16-16 liblcms2-2 libxml2-utils fonts-dejavu && \
    rm -rf /var/lib/apt/lists/*

##########################################
# Builder for native libs
##########################################
FROM base AS builder

ARG LIB_JXL_VERSION=0.11.1
ARG LIB_WEBP_VERSION=1.5.0
ARG LIB_AOM_VERSION=3.12.1
ARG LIB_HEIF_VERSION=1.20.0
ARG MOZJPEG_VERSION=4.1.1

WORKDIR /build

# Build libjxl
RUN git clone -b v${LIB_JXL_VERSION} --depth 1 --recursive https://github.com/libjxl/libjxl.git && \
    mkdir libjxl/build && cd libjxl/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && \
    make -j$(nproc) && make install && ldconfig && cd ../.. && rm -rf libjxl

# Build libwebp
RUN git clone -b v${LIB_WEBP_VERSION} --depth 1 https://chromium.googlesource.com/webm/libwebp && \
    cd libwebp && ./autogen.sh && ./configure && make -j$(nproc) && make install && cd .. && rm -rf libwebp

# Build libaom
RUN git clone -b v${LIB_AOM_VERSION} --depth 1 https://aomedia.googlesource.com/aom && \
    mkdir build_aom && cd build_aom && \
    cmake ../aom/ -DAOM_TARGET_CPU=generic -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && \
    make -j$(nproc) && make install && ldconfig && cd .. && rm -rf aom build_aom

# Build libheif
RUN curl -L -o libheif.tar.gz https://github.com/strukturag/libheif/releases/download/v${LIB_HEIF_VERSION}/libheif-${LIB_HEIF_VERSION}.tar.gz && \
    tar xzf libheif.tar.gz && cd libheif-${LIB_HEIF_VERSION} && \
    mkdir build && cd build && cmake --preset=release .. && \
    make -j$(nproc) && make install && ldconfig && cd ../.. && rm -rf libheif-${LIB_HEIF_VERSION} libheif.tar.gz

# Build MozJPEG
RUN wget https://github.com/mozilla/mozjpeg/archive/refs/tags/v${MOZJPEG_VERSION}.tar.gz && \
    tar xzf v${MOZJPEG_VERSION}.tar.gz && cd mozjpeg-${MOZJPEG_VERSION} && \
    cmake . && make -j$(nproc) && make install && ldconfig && cd .. && rm -rf mozjpeg-${MOZJPEG_VERSION} v${MOZJPEG_VERSION}.tar.gz

##########################################
# Final Image
##########################################
FROM base AS final

COPY --from=builder /usr/local /usr/local

# Install ImageMagick
ARG IM_VERSION=7.1.1-47
RUN git clone -b ${IM_VERSION} --depth 1 https://github.com/ImageMagick/ImageMagick.git && \
    cd ImageMagick && ./configure --without-magick-plus-plus --disable-docs --disable-static \
    --with-tiff --with-jxl --with-tcmalloc && make -j$(nproc) && make install && ldconfig && cd .. && rm -rf ImageMagick

# PHP Extensions
RUN docker-php-ext-install opcache && \
    pecl install yaml xdebug && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini && \
    echo "zend_extension=xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/xdebug.ini

# Python deps
ARG PILLOW_VERSION=11.3.0
ARG PILLOW_AVIF_PLUGIN_VERSION=1.5.2
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install numpy pillow==${PILLOW_VERSION} pillow-avif-plugin==${PILLOW_AVIF_PLUGIN_VERSION}

# To creates the necessary links and cache in /usr/local/lib
RUN ldconfig /usr/local/lib

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy configs
COPY resources/etc/ /etc/
COPY resources/php-fpm.d/ /usr/local/etc/php-fpm.d/
COPY resources/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

RUN rm -f /etc/nginx/conf.d/default.conf || true

ENV PORT 80
WORKDIR /var/www/html
ENTRYPOINT ["docker-entrypoint", "/init"]
