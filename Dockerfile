FROM php:7.1-apache

MAINTAINER Eli Van Zoeren

ENV PUBLIC_FOLDER="/public_html" \
    PHP_INI="/usr/local/etc/php/conf.d/custom.ini"

# Enable mod_rewrite in Apache config
RUN a2enmod rewrite

# Install PHP extensions
RUN apt-get update && apt-get install -yqq --no-install-recommends \
        libfreetype6-dev libpng-dev libtiff-dev libgif-dev libpng12-dev libjpeg-dev webp \
        libmcrypt-dev ssmtp libmagickwand-dev \
        rsync git sudo openssh-client ca-certificates tar gzip unzip zip \
    && apt-get -y autoremove && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && pecl install imagick redis xdebug \
    && docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr \
    && docker-php-ext-install gd mbstring mysqli pdo pdo_mysql opcache iconv mcrypt calendar zip \
    && docker-php-ext-enable imagick redis xdebug

# PHP configuration
RUN touch $PHP_INI \
    && echo "xdebug.remote_enable = 1" >> $PHP_INI \
    && echo "xdebug.max_nesting_level = 1000" >> $PHP_INI \
    && echo "xdebug.profiler_enable_trigger = 1" >> $PHP_INI \
    && echo "xdebug.profiler_output_dir = "/var/log"" >> $PHP_INI \
    && echo "opcache.memory_consumption = 128" >> $PHP_INI \
    && echo "opcache.revalidate_freq = 0" >> $PHP_INI \
    && echo "opcache.fast_shutdown = 1" >> $PHP_INI \
    && echo "sendmail_path = '/usr/sbin/ssmtp -t'" >> $PHP_INI \
    && echo "upload_max_filesize = 128M" >> $PHP_INI \
    && echo "post_max_size = 128M" >> $PHP_INI \
    && echo "memory_limit = 1024M" >> $PHP_INI \
    && echo "mailhub=mail:1025\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf

# Install Composer & WP-CLI
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer \
    && mkdir /var/tmp/.composer && chmod 777 /var/tmp/.composer && composer config -g set home /var/tmp/.composer \
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Install Node, Yarn, & Gulp
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y build-essential nodejs yarn \
    && mkdir /var/tmp/yarn && chmod 777 /var/tmp/yarn && yarn config set cache-folder /var/tmp/yarn \
    && /usr/bin/npm install -g gulp

# Set webroot directory for Apache virtual host
RUN sed -ri -e \
        's!/var/www/html!/var/www${PUBLIC_FOLDER}!g' \
        /etc/apache2/sites-available/*.conf \
    && sed -ri -e \
        's!/var/www/html!/var/www${PUBLIC_FOLDER}!g' \
        /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

WORKDIR /var/www
