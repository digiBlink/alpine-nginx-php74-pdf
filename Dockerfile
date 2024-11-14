# final stage
FROM php:7.4.33-fpm-alpine3.16@sha256:0aeb129a60daff2874c5c70fcd9d88cdf3015b4fb4cc7c3f1a32a21e84631036

LABEL org.opencontainers.image.source https://github.com/digiblink/alpine-nginx-php74-pdf
LABEL org.opencontainers.image.description Alpine Linux Docker image with Nginx, PHP-FPM and wkhtmltopdf

RUN apk -u add nginx wkhtmltopdf

RUN docker-php-ext-install pdo_mysql \
    && docker-php-ext-install opcache

RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/php-opocache-cfg.ini

# phalcon version setting
ARG PSR_VERSION=1.2.0
ARG PHALCON_VERSION=5.8.0
ARG PHALCON_EXT_PATH=php7/64bits

RUN set -xe && \
   # install PSR
   curl -LO https://github.com/jbboehr/php-psr/archive/v${PSR_VERSION}.tar.gz && \
   tar xzf ${PWD}/v${PSR_VERSION}.tar.gz && \
   # install Phalcon
   curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
   tar xzf ${PWD}/v${PHALCON_VERSION}.tar.gz && \
   docker-php-ext-install -j $(getconf _NPROCESSORS_ONLN) \
       ${PWD}/php-psr-${PSR_VERSION} \
       ${PWD}/cphalcon-${PHALCON_VERSION}/build/${PHALCON_EXT_PATH} \
   && \
   # remove tmp file
   rm -r \
       ${PWD}/v${PSR_VERSION}.tar.gz \
       ${PWD}/php-psr-${PSR_VERSION} \
       ${PWD}/v${PHALCON_VERSION}.tar.gz \
       ${PWD}/cphalcon-${PHALCON_VERSION} \
   && \
   php -m

ENV DB_HOST="" \
    DB_PORT="3306" \
    DB_DATABASE="" \
    DB_USERNAME="" \
    DB_PASSWORD=""

RUN mkdir -p /app/public

WORKDIR /app

COPY ./files/nginx.conf /etc/nginx
COPY ./files/default.conf /etc/nginx/http.d
COPY ./files/php.ini /usr/local/etc/php
COPY ./files/www.conf /usr/local/etc/php-fpm.d
COPY ./files/entrypoint.sh /entrypoint.sh
COPY ./files/index.php /app/public

RUN set -eux; \
    chmod +x /entrypoint.sh; \
    addgroup -g 1000 -S app; \
    adduser -S -h /app -D -u 1000 -s /bin/sh app app; \
    touch /var/run/nginx.pid; \
    chown -R 1000:1000 /var/run/nginx.pid; \
    chown -R 1000:1000 /var/lib/nginx; \
    chown -R 1000:1000 /var/log/nginx; \
    chown -R 1000:1000 /run/nginx; \
    chown -R 1000:1000 /app

EXPOSE 8080

USER 1000

ENTRYPOINT ["/entrypoint.sh"]
