# Setup php, apache and stud.ip
FROM php:7.4-apache

# Install system requirements
RUN apt update && apt install -y  --no-install-recommends \
    subversion default-mysql-client default-libmysqlclient-dev libcurl4-openssl-dev zlib1g-dev libpng-dev libonig-dev libzip-dev libicu-dev unzip git \
    curl apt-transport-https ca-certificates lsb-release gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install php extensions
RUN docker-php-ext-install pdo gettext curl gd mbstring zip pdo pdo_mysql mysqli intl json

# Install npm using nvm
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt update && apt install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install composer
COPY composer.sh /tmp/composer.sh
RUN chmod u+x /tmp/composer.sh
RUN /tmp/composer.sh

# Branch Arg
ARG BRANCH=trunk

# Checkout studip
RUN svn export  --username=studip --password=studip --non-interactive "svn://develop.studip.de/studip/$BRANCH" /var/www/studip

# Reconfigure apache
ENV APACHE_DOCUMENT_ROOT /var/www/studip/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Execute make to install composer dependencies and build assets
WORKDIR /var/www/studip
RUN make

# Add config template
COPY config_local.php /config/config_local.inc.php

# Add custom entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-entrypoint.sh

# Set start parameters
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
