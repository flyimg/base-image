FROM php:7.1-fpm

MAINTAINER sadoknet@gmail.com
ENV DEBIAN_FRONTEND=noninteractive

RUN \
  	apt-get -y update && \
  	apt-get -y install \
  	nginx supervisor zip unzip\
	imagemagick webp &&\
#install dependencies
 	apt-get -y install \
    gcc nasm build-essential make wget vim git && \
    echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -

#PHP7 dependencies
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

COPY .    /var/www/html

WORKDIR /var/www/html

#add www-data + mdkdir var folder
RUN usermod -u 1000 www-data && \
    mkdir -p /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var && \
    mkdir -p var/cache/ var/log/ var/sessions/ web/uploads/.tmb && \
    chown -R www-data:www-data var/  web/uploads/ && \
    chmod 777 -R var/  web/uploads/

EXPOSE 80

CMD ln /dev/null /dev/raw1394;/usr/bin/supervisord
