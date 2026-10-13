FROM alpine:3.23

ARG WP_VERSION=6.9.4
ARG WP_CLI_VERSION=2.12.0
ARG REDIS_CACHE_VERSION=2.7.0

RUN apk add --no-cache \
    php84 \
    php84-fpm \
    php84-phar \
    php84-mysqli \
    php84-curl \
    php84-dom \
    php84-exif \
    php84-fileinfo \
    php84-mbstring \
    php84-openssl \
    php84-xml \
    php84-zip \
    php84-iconv \
    php84-ctype \
    php84-tokenizer \
    php84-session \
    php84-gd \
    php84-intl \
    php84-pecl-redis \
    curl

RUN curl -fsSL -o /usr/local/bin/wp \
        https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar && \
    chmod +x /usr/local/bin/wp && \
    mkdir -p /usr/src && rm -rf /var/www/localhost && \
    curl -fsSL https://wordpress.org/wordpress-${WP_VERSION}.tar.gz | tar -xz -C /usr/src && \
    curl -fsSL -o /usr/src/redis-cache.zip \
        https://downloads.wordpress.org/plugin/redis-cache.${REDIS_CACHE_VERSION}.zip

COPY conf/www.conf /etc/php84/php-fpm.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www

EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm84", "-F"]
