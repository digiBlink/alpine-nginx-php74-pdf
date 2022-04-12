# final stage
FROM php:7.4.28-fpm-alpine3.14

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

ENV DB_HOST="" \
    DB_PORT="3306" \
    DB_DATABASE="" \
    DB_USERNAME="" \
    DB_PASSWORD=""

WORKDIR /app

COPY ./files/nginx.conf /etc/nginx
COPY ./files/default.conf /etc/nginx/http.d
COPY ./files/php.ini /usr/local/etc/php
COPY ./files/www.conf /usr/local/etc/php-fpm.d
COPY ./files/entrypoint.sh /entrypoint.sh

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
