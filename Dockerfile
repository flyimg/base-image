FROM php:8.2-fpm-bullseye

ENV DEBIAN_FRONTEND=noninteractive

ARG IM_VERSION=7.1.1-32
ARG LIB_HEIF_VERSION=1.17.6
ARG LIB_AOM_VERSION=3.9.0
ARG LIB_WEBP_VERSION=1.4.0
ARG LIBJXL_VERSION=0.10.2
ARG TARGETPLATFORM

# Install s6-overlay
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v8" ]; then ARCHITECTURE=arm; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=aarch64; \
    else ARCHITECTURE=amd64; fi \
    && curl -sS -L -O --output-dir /tmp/ --create-dirs https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-${ARCHITECTURE}.tar.gz \
    && tar xzf /tmp/s6-overlay-${ARCHITECTURE}.tar.gz -C /

# Install dependencies and main libraries needed for ImageMagick
RUN \
    apt-get -y update && \
    apt-get install -y --no-install-recommends  \
    wget nginx libyaml-dev python3-distutils zip unzip\
    git make pkg-config autoconf curl cmake clang libompl-dev ca-certificates automake yasm \
    # libheif
    libde265-0 libde265-dev libjpeg62-turbo libjpeg62-turbo-dev x265 libx265-dev libtool \
    # libwebp
    libsdl1.2-dev libgif-dev \
    # libjxl
    libbrotli-dev \
    # IM
    webp opencv-data libpng16-16 libpng-dev libjpeg62-turbo libjpeg62-turbo-dev libgomp1  \
    ghostscript ffmpeg \
    libxml2-dev libxml2-utils libtiff-dev libfontconfig1-dev libfreetype6-dev fonts-dejavu liblcms2-2 liblcms2-dev libtcmalloc-minimal4 \
    libxext6 libbrotli1 && \
    export CC=clang CXX=clang++ && \
    # Building libjxl
    git clone -b v${LIBJXL_VERSION} https://github.com/libjxl/libjxl.git --depth 1 --recursive --shallow-submodules && \
    cd libjxl && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && \
    cmake --build . -- -j$(nproc) && \
    cmake --install . && \
    cd ../../ && \
    rm -rf libjxl && \
    ldconfig /usr/local/lib && \
    # Building libwebp
    git clone -b v${LIB_WEBP_VERSION} --depth 1 https://chromium.googlesource.com/webm/libwebp && \
    cd libwebp && \
    mkdir build && cd build && cmake ../ && make && make install && \
    make && make install && \
    ldconfig /usr/local/lib && \
    cd ../../ && rm -rf libwebp && \
    # Building libaom
    git clone -b v${LIB_AOM_VERSION} --depth 1 https://aomedia.googlesource.com/aom && \
    mkdir build_aom && \
    cd build_aom && \
    cmake ../aom/ -DAOM_TARGET_CPU=generic -DENABLE_TESTS=0 -DBUILD_SHARED_LIBS=1 && make && make install && \
    ldconfig /usr/local/lib && \
    cd .. && \
    rm -rf aom && \
    rm -rf build_aom && \
    # Building libheif
    curl -L https://github.com/strukturag/libheif/releases/download/v${LIB_HEIF_VERSION}/libheif-${LIB_HEIF_VERSION}.tar.gz -o libheif.tar.gz && \
    tar -xzvf libheif.tar.gz && cd libheif-${LIB_HEIF_VERSION}/ && mkdir build && cd build && cmake --preset=release .. && make && make install && cd ../../ \
    ldconfig /usr/local/lib && \
    rm -rf libheif-${LIB_HEIF_VERSION} && rm libheif.tar.gz && \
    # Building ImageMagick
    git clone -b ${IM_VERSION} --depth 1 https://github.com/ImageMagick/ImageMagick.git && \
    cd ImageMagick && \
    ./configure --without-magick-plus-plus --disable-docs --disable-static --with-tiff --with-jxl --with-tcmalloc && \
    make && make install && \
    ldconfig /usr/local/lib && \
    rm -rf /ImageMagick

# Opcache
RUN docker-php-ext-install opcache

# Additional libraries
RUN pecl install yaml xdebug && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini && \
    echo "zend_extension=xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "error_reporting=E_ALL & ~E_DEPRECATED & ~E_STRICT" >> /usr/local/etc/php/conf.d/error_reporting.ini && \
    echo "expose_php=off" > /usr/local/etc/php/conf.d/expose_php.ini

# Install MozJPEG
RUN \
    cd /opt && \
    wget "https://github.com/mozilla/mozjpeg/archive/refs/tags/v4.1.1.tar.gz" && \
    tar xvf "v4.1.1.tar.gz" && \
    rm v4.1.1.tar.gz && \
    mv mozjpeg-4.1.1  mozjpeg&& \
    cd mozjpeg && \
    cmake . && \
    make

# Install OpenCV
RUN \
    apt-get -y update && \
    apt-get install -y python3-dev libssl-dev python3-opencv

# Facedetect script
RUN \
    cd /var && \
    curl https://bootstrap.pypa.io/pip/3.5/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    python3 -m pip install --upgrade pip && \
    pip3 install numpy pillow && \
    git clone https://github.com/flyimg/facedetect.git && \
    chmod +x /var/facedetect/facedetect && ln -s /var/facedetect/facedetect /usr/local/bin/facedetect

# pillow-avif-plugin only available for amd64/arm64 arch
# https://github.com/python-pillow/Pillow/pull/5201
# https://github.com/fdintino/pillow-avif-plugin/pull/38
RUN if [ "$TARGETPLATFORM" = "linux/amd64" -o "$TARGETPLATFORM" = "linux/arm64" ]; then \
        pip3 install pillow-avif-plugin; \
    fi

# To creates the necessary links and cache in /usr/local/lib
RUN ldconfig /usr/local/lib

# Smart Crop python
RUN pip install git+https://github.com/flyimg/python-smart-crop

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Disable output access.log to stdout
RUN sed -i -e 's#access.log = /proc/self/fd/2#access.log = /proc/self/fd/1#g'  /usr/local/etc/php-fpm.d/docker.conf

# Copy etc/
COPY resources/etc/ /etc/
COPY resources/php-fpm.d/ /usr/local/etc/php-fpm.d/

ENV PORT 80

COPY resources/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint", "/init"]