ARG PHP_VERSION=8.5

FROM dunglas/frankenphp:php${PHP_VERSION} AS base

ARG COMPOSER_VERSION
ARG GID
ARG GROUP_NAME
ARG UID
ARG USER_NAME

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        libonig-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-install -j$(nproc) bcmath gd mbstring pcntl pdo_mysql zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/bin --filename=composer --version=$COMPOSER_VERSION \
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -g $GID $GROUP_NAME \
    && useradd -u $UID -ms /bin/bash -g $GROUP_NAME $USER_NAME

WORKDIR /var/www/html

FROM base AS dev

ARG NODE_VERSION
ARG PNPM_VERSION
ARG XDEBUG_VERSION
ARG USER_NAME
ARG GROUP_NAME

RUN pecl install xdebug-${XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug

RUN apt-get update && apt-get install -y --no-install-recommends \
        gnupg \
        supervisor \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && corepack enable \
    && corepack prepare pnpm@$PNPM_VERSION --activate \
    && npm cache clean --force \
    && pnpm store prune \
    && apt-get autoremove -y && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./hybridly/conf.d/ /etc/supervisor/conf.d/
COPY ./hybridly/config/php.ini /usr/local/etc/php/php.ini
COPY ./hybridly/ssl/rootCA.pem /usr/local/share/ca-certificates/rootCA.crt
COPY ./hybridly/supervisord.conf /etc/supervisor/supervisord.conf

RUN update-ca-certificates
RUN mkdir -p /var/log/supervisor && chown $USER_NAME:$GROUP_NAME /var/log/supervisor

USER $USER_NAME

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]

FROM base AS prod

ARG USER_NAME

USER $USER_NAME

CMD ["php", "artisan", "octane:start", "--server=frankenphp", "--host=0.0.0.0", "--port=8000"]
