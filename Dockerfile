FROM php:7.1-fpm

MAINTAINER sadoknet@gmail.com
ENV DEBIAN_FRONTEND=noninteractive

RUN \
  	apt-get -y update && \
  	apt-get -y install \
  	nginx supervisor zip unzip\
	imagemagick webp libmagickwand-dev libyaml-dev\
    gcc nasm build-essential make wget vim git

#opcache
RUN docker-php-ext-install opcache

#xdebug
RUN pecl install xdebug \
    && echo "zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20160303/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini

#Imagick
RUN pecl install imagick \
    && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/imagick.ini

#yaml-2.0.0
RUN pecl install yaml-2.0.0 \
    && echo "extension=yaml.so" > /usr/local/etc/php/conf.d/yaml.ini

#install MozJPEG
RUN \
    wget "https://github.com/mozilla/mozjpeg/releases/download/v3.2/mozjpeg-3.2-release-source.tar.gz" && \
    tar xvf "mozjpeg-3.2-release-source.tar.gz" && \
    cd mozjpeg && \
    ./configure && \
    make && \
    make install

#facedetect script
RUN \
	cd /var && \
    apt-get -y install python3 python3-numpy libopencv-dev python3-setuptools && \
    easy_install3 pip && \
    pip install numpy && \
    pip install opencv-python && \
    git clone https://github.com/wavexx/facedetect.git && \
    chmod +x /var/facedetect/facedetect && \
    ln -s /var/facedetect/facedetect /usr/local/bin/facedetect

#composer
RUN \
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#Disable output access.log to stdout
RUN sed -i -e 's#access.log = /proc/self/fd/2#access.log = /proc/self/fd/1#g'  /usr/local/etc/php-fpm.d/docker.conf

#copy etc/
COPY resources/etc/ /etc/

WORKDIR /var/www/html

EXPOSE 80

CMD /usr/bin/supervisord
