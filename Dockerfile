FROM php:8.2-fpm-bullseye

ENV DEBIAN_FRONTEND=noninteractive

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

#Update stretch repositories
# RUN rm -rf /etc/apt/sources.list.d/* && \
#     echo "deb http://archive.debian.org/debian bullseye main contrib non-free" | tee /etc/apt/sources.list

RUN \
    apt clean && \
    apt autoclean && \
    apt autoremove && \
    apt -y update && \
    apt -y install --no-install-recommends --allow-downgrades\
    nginx zip unzip 

RUN apt -y install --no-install-recommends --allow-downgrades \
    libxml2 libxml2-dev 
RUN  apt -y install --no-install-recommends --allow-downgrades libmagickcore-dev

RUN  apt -y install --no-install-recommends webp libmagickwand-dev libyaml-dev 
RUN  apt -y install --no-install-recommends python3-numpy libopencv-dev python3-setuptools opencv-data 
RUN  apt -y install --no-install-recommends gcc nasm build-essential make libpng-dev zlib1g-dev cmake wget vim git && \
    rm -rf /var/lib/apt/lists/*

# #opcache
RUN docker-php-ext-install opcache

RUN wget https://download.imagemagick.org/ImageMagick/download/ImageMagick.tar.gz && \
    tar xvf ImageMagick.tar.gz && \
    rm -rf ImageMagick.tar.gz && \
    cd ImageMagick-7*/ && \
    ./configure && \
    make && \
    make install && \
    ldconfig /usr/local/lib

# #additional libraries
RUN pecl install imagick yaml xdebug && \
    echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini && \
    echo "extension=imagick.so" > /usr/local/etc/php/conf.d/imagick.ini && \
    echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20220829/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "expose_php=off" > /usr/local/etc/php/conf.d/expose_php.ini

# #install MozJPEG
RUN \
    cd /opt && \
    wget "https://github.com/mozilla/mozjpeg/archive/refs/tags/v4.1.1.tar.gz" && \
    tar xvf "v4.1.1.tar.gz" && \
    rm v4.1.1.tar.gz && \
    mv mozjpeg-4.1.1  mozjpeg&& \
    cd mozjpeg && \
    cmake . && \
    make

#facedetect script
RUN \
    cd /var && \
    curl https://bootstrap.pypa.io/pip/3.5/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    pip3 install numpy && \
    pip3 install opencv-python && \
    git clone https://github.com/flyimg/facedetect.git && \
    chmod +x /var/facedetect/facedetect && ln -s /var/facedetect/facedetect /usr/local/bin/facedetect

#Smart Crop python
RUN pip install git+https://github.com/flyimg/python-smart-crop

#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#disable output access.log to stdout
RUN sed -i -e 's#access.log = /proc/self/fd/2#access.log = /proc/self/fd/1#g'  /usr/local/etc/php-fpm.d/docker.conf

#copy etc/
COPY resources/etc/ /etc/

ENV PORT 80

COPY resources/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint", "/init"]

