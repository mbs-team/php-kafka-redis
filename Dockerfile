FROM php:7.2-fpm-alpine
ARG TIMEZONE=UTC
ARG MAX_UPLOAD='128M'

# Set timezone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone
RUN printf '[PHP]\ndate.timezone = "%s"\n' '${TIMEZONE}' > /usr/local/etc/php/conf.d/tzone.ini

# Max Upload
RUN printf '[PHP]\npost_max_size = "%s"\n' '${MAX_UPLOAD}' > /usr/local/etc/php/conf.d/upload.ini
RUN printf 'upload_max_filesize = "%s"\n' '${MAX_UPLOAD}' >> /usr/local/etc/php/conf.d/upload.ini

RUN wget https://getcomposer.org/installer -O - -q | php -- --quiet && \
    mv composer.phar /usr/local/bin/composer

# Increase memory limit
RUN echo 'memory_limit = -1' >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini;

# Extension dependencies
RUN apk --no-cache add libffi-dev postgresql-dev zlib-dev icu-dev librdkafka-dev libpng-dev libxml2-dev
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# PHP extensions
RUN docker-php-ext-install pdo pdo_pgsql zip intl hash opcache bcmath pcntl sockets gd soap

# PHP PECL extensions
RUN docker-php-source extract \
    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && pecl install apcu \
    && docker-php-ext-enable apcu  \
    && pecl install rdkafka \
    && docker-php-ext-enable rdkafka \
    && apk del .phpize-deps-configure \
    && docker-php-source delete
