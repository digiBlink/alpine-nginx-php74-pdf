# final stage
FROM php:7.4.29-fpm-alpine3.14@sha256:08d205874f4a1942d9cd07e9f1490dbe5ea3a4cdb707b4e4d252ea7a3c5b8348

LABEL org.opencontainers.image.source https://github.com/digiblink/alpine-nginx-php74-pdf
LABEL org.opencontainers.image.description Alpine Linux Docker image with Nginx, PHP-FPM and wkhtmltopdf

RUN apk -u add nginx wkhtmltopdf php7-phalcon

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
