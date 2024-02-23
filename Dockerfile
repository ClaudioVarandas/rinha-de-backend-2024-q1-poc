FROM php:8.2.15-fpm-alpine3.18

ARG PHALCON_VERSION=5.6.1
ARG COMPOSER_VERSION="2.6.6"
ARG COMPOSER_SUM="72600201c73c7c4b218f1c0511b36d8537963e36aafa244757f52309f885b314"

# Install dependencies
RUN set -eux \
    && apk add --no-cache \
        c-client \
        ca-certificates \
        freetds \
        freetype \
        gettext \
        gmp \
        icu-libs \
        imagemagick \
        imap \
        libffi \
        libgmpxx \
        libintl \
        libjpeg-turbo \
        libpng \
        libpq \
        librdkafka \
        libssh2 \
        libstdc++ \
        libtool \
        libxpm \
        libxslt \
        libzip \
        lz4-libs \
        make \
        rabbitmq-c \
        tidyhtml \
        tzdata \
        unixodbc \
        vips \
        yaml \
        zstd-libs

################################
# Install PHP extensions
################################

# Development dependencies
RUN set -eux \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        bzip2-dev \
        cmake \
        curl-dev \
        freetds-dev \
        freetype-dev \
        g++ \
        gcc \
        gettext-dev \
        git \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        imap-dev \
        krb5-dev \
        libc-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        librdkafka-dev \
        libssh2-dev \
        libwebp-dev \
        libxml2-dev \
        libxpm-dev \
        libxslt-dev \
        libzip-dev \
        lz4-dev \
        openssl-dev \
        pcre-dev \
        pkgconf \
        postgresql-dev \
        rabbitmq-c-dev \
        tidyhtml-dev \
        unixodbc-dev \
        vips-dev \
        yaml-dev \
        zlib-dev \
        zstd-dev \
\
# Workaround for rabbitmq linking issue
    && ln -s /usr/lib /usr/local/lib64 \
\
# Enable ffi if it exists
    && set -eux \
    && if [ -f /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini ]; then \
        echo "ffi.enable = 1" >> /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini; \
    fi \
\
# Install opcache
    && docker-php-ext-install -j$(nproc) opcache

# Install phalcon
RUN git clone --depth=1 --branch=v${PHALCON_VERSION} https://github.com/phalcon/cphalcon.git /opt/phalcon \
    && cd /opt/phalcon/build \
    && sh ./install \
    && docker-php-ext-enable phalcon

RUN docker-php-ext-install -j$(nproc) pdo_pgsql \
    && true \
    && docker-php-ext-install -j$(nproc) pgsql

#########################
# Clean up build packages
RUN docker-php-source delete \
    && apk del .build-deps \
    && rm -rf /tmp/*

RUN set -eux \
# Fix php.ini settings for enabled extensions
    && chmod +x "$(php -r 'echo ini_get("extension_dir");')"/* \
# Shrink binaries
    && (find /usr/local/bin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && (find /usr/local/lib -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
    && (find /usr/local/sbin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true)

# Install Composer
# Composer - https://getcomposer.org/download/
RUN set -eux \
    && curl -LO "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" \
    && echo "${COMPOSER_SUM}  composer.phar" | sha256sum -c - \
    && chmod +x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && composer --version

# Copy PHP-FPM configuration files
COPY docker/8.2-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/8.2-fpm/entrypoint.sh /entrypoint.sh
COPY src /application

RUN chmod u+x /entrypoint.sh

WORKDIR /application

STOPSIGNAL SIGQUIT

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 9000

CMD ["php-fpm"]