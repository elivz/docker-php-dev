FROM php:7.1-apache

MAINTAINER Eli Van Zoeren

ENV WEBROOT /var/www/public_html
ENV PHP_INI /usr/local/etc/php/conf.d/custom.ini

# Enable mod_rewrite in Apache config
RUN a2enmod rewrite

# Install PHP extensions
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libpng-dev \
        libtiff-dev \
        libgif-dev \
        libpng12-dev \
        libjpeg-dev \
        webp \
        libmcrypt-dev \
        ssmtp \
        libmagickwand-dev \
        --no-install-recommends && rm -r /var/lib/apt/lists/* \
    && pecl install imagick redis xdebug \
    && docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr \
    && docker-php-ext-install gd mbstring mysqli pdo pdo_mysql opcache iconv mcrypt calendar \
    && docker-php-ext-enable imagick redis xdebug

# PHP configurationf
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
    && echo "post_max_size = 128M" >> $PHP_INI

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Set webroot directory for Apache virtual host
RUN sed -ri -e \
        's!/var/www/html!${WEBROOT}!g' \
        /etc/apache2/sites-available/*.conf
RUN sed -ri -e \
        's!/var/www/html!${WEBROOT}!g' \
        /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Route mail through MailCatcher
RUN echo "mailhub=mail:1025\nUseTLS=NO\nFromLineOverride=YES" > /etc/ssmtp/ssmtp.conf

USER www-data

WORKDIR $WEBROOT