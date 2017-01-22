FROM php:7.0-fpm

MAINTAINER sadoknet@gmail.com
ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get -y update && \
  apt-get -y install \
  nginx supervisor


#install dependencies
RUN apt-get -y install \
    imagemagick \
    gcc nasm build-essential make wget vim git

RUN echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list.d/dotdeb.org.list && \
    wget -O- http://www.dotdeb.org/dotdeb.gpg | apt-key add -

#PHP7 dependencies
RUN apt-get -y update && \
    apt-get -y install \
    php7.0-intl php-pear \
    php7.0-imap php7.0-mcrypt \
    php7.0-xdebug && \
    docker-php-ext-install opcache

RUN \
    echo "extension=/usr/lib/php/20151012/intl.so" > /usr/local/etc/php/conf.d/intl.ini && \
    echo "zend_extension=/usr/lib/php/20151012/xdebug.so" > /usr/local/etc/php/conf.d/xdebug.ini


#install MozJPEG
RUN \
    wget "https://github.com/mozilla/mozjpeg/releases/download/v3.1/mozjpeg-3.1-release-source.tar.gz" && \
    tar xvf "mozjpeg-3.1-release-source.tar.gz" && \
    cd mozjpeg && \
    ./configure && \
    make && \
    make install

#facedetect script
WORKDIR /var

RUN \
    apt-get -y install python-numpy libopencv-dev python-opencv && \
    git clone https://github.com/wavexx/facedetect.git && \
    chmod +x /var/facedetect/facedetect && \
    ln -s /var/facedetect/facedetect /usr/local/bin/facedetect

RUN echo "\nln /dev/null /dev/raw1394" >> ~/.bashrc


#composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#install phpUnit
RUN \
    wget https://phar.phpunit.de/phpunit.phar && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit


RUN apt-get -y upgrade nginx

#copy etc/
COPY docker/resources/etc/ /etc/

COPY .    /var/www/html

WORKDIR /var/www/html

#add www-data + mdkdir var folder
RUN usermod -u 1000 www-data && \
    mkdir -p /var/www/html/var && \
    chown -R www-data:www-data /var/www/html/var

RUN mkdir -p var/cache/ var/logs/ var/sessions/ web/uploads/.tmb && \
    chown -R www-data:www-data var/  web/uploads/ && \
    chmod 777 -R var/  web/uploads/


EXPOSE 80

CMD ["/usr/bin/supervisord"]