FROM php:7.1-apache

MAINTAINER Eli Van Zoeren

ENV PUBLIC_FOLDER="/public_html"

# Enable mod_rewrite in Apache config
RUN a2enmod rewrite

# Install PHP extensions
RUN apt-get update && apt-get install -yqq --no-install-recommends \
    autoconf automake libtool nasm make pkg-config git sudo libicu-dev libmcrypt-dev ssmtp \
    libfreetype6-dev libpng12-dev libtiff-dev libgif-dev libjpeg-dev libmagickwand-dev \
    jpegoptim optipng webp rsync openssh-client ca-certificates tar gzip unzip zip \
    && apt-get -y autoremove && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && pecl install imagick redis xdebug \
    && docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr \
    && docker-php-ext-install gd mbstring mysqli pdo pdo_mysql opcache iconv mcrypt calendar zip intl \
    && docker-php-ext-enable imagick redis xdebug

# PHP configuration
COPY custom.ini /usr/local/etc/php/conf.d/
RUN echo "mailhub=mail:1025\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Install Node, Yarn, Gulp, & SVGO
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y build-essential nodejs yarn \
    && /usr/bin/npm install -g gulp svgo \
    && /usr/bin/yarn config set cache-folder /var/tmp/yarn

# Set webroot directory for Apache virtual host
RUN sed -ri -e \
    's!/var/www/html!/var/www${PUBLIC_FOLDER}!g' \
    /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf /etc/apache2/sites-available/*.conf

WORKDIR /var/www
