FROM php:7.1-fpm

MAINTAINER sadoknet@gmail.com
ENV DEBIAN_FRONTEND=noninteractive

RUN \
  	apt-get -y update && \
  	apt-get -y install \
  	nginx supervisor zip unzip\
	imagemagick webp \
    gcc nasm build-essential make wget vim git

#opcache
RUN docker-php-ext-install opcache

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

#copy etc/
COPY resources/etc/ /etc/

WORKDIR /var/www/html

EXPOSE 80

CMD /usr/bin/supervisord
