FROM php:7.3-apache

MAINTAINER Eli Van Zoeren <eli@elivz.com>

ENV PUBLIC_FOLDER /public_html

# Enable mod_rewrite in Apache config
RUN a2enmod rewrite

# Set webroot directory for Apache virtual host
RUN sed -ri -e \
  's!/var/www/html!/var/www${PUBLIC_FOLDER}!g' \
  /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf /etc/apache2/sites-available/*.conf

# Install PHP extension dependencies
RUN apt-get update && apt-get install -yqq --no-install-recommends \
  autoconf automake libtool libpq-dev nasm make pkg-config git sudo libicu-dev \
  libfreetype6-dev libpng-dev libtiff-dev libgif-dev libjpeg-dev libmagickwand-dev ghostscript \
  jpegoptim optipng webp rsync openssh-client ca-certificates tar gzip unzip zip libzip-dev gnupg \
  && apt-get -y autoremove && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install PHP extensions
RUN pecl install imagick redis xdebug \
  && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
  && docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr \
  && docker-php-ext-install gd bcmath mbstring mysqli pgsql pdo pdo_mysql pdo_pgsql opcache iconv calendar zip intl \
  && docker-php-ext-enable imagick redis xdebug

# PHP configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY custom.ini /usr/local/etc/php/conf.d/

# Install Composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp/composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer \
  && /usr/local/bin/composer global require hirak/prestissimo

# Install Node, Yarn, Gulp, & SVGO
ENV YARN_CACHE_FOLDER=/tmp/yarn
ENV npm_config_cache=/tmp/npm
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install -y build-essential nodejs yarn \
  && /usr/bin/npm install -g npm gulp svgo

# Create necessary folders owned by the web user
RUN mkdir /tmp/yarn && chown -R www-data:www-data /tmp/yarn \
  && mkdir /var/www/node_modules && chown -R www-data:www-data /var/www/node_modules \
  && mkdir /var/www/dist && chown -R www-data:www-data /var/www/dist \
  && mkdir /var/www/dist/vendor && chown -R www-data:www-data /var/www/dist/vendor \
  && mkdir /var/www/dist/storage && mkdir /var/www/dist/storage/runtime && chown -R www-data:www-data /var/www/dist/storage/runtime \
  && chown -R www-data:www-data /tmp/npm \
  && chown -R www-data:www-data /tmp/composer*

WORKDIR /var/www
