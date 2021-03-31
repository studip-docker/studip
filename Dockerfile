# Setup php, apache and stud.ip
FROM php:7.4-apache

# Install system requirements
RUN apt update && apt install -y  --no-install-recommends \
    subversion default-mysql-client libcurl4-openssl-dev zlib1g-dev libpng-dev libonig-dev libzip-dev libicu-dev unzip git \
    && rm -rf /var/lib/apt/lists/*

# Install php extensions
RUN docker-php-ext-install pdo gettext curl gd mbstring zip pdo pdo_mysql mysqli intl json

# Branch Arg
ARG BRANCH=branches/4.5

# Checkout studip
RUN svn export  --username=studip --password=studip --non-interactive "svn://develop.studip.de/studip/$BRANCH" /var/www/studip

# Reconfigure apache
ENV APACHE_DOCUMENT_ROOT /var/www/studip/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install composer
COPY composer.sh /tmp/composer.sh
RUN chmod u+x /tmp/composer.sh
RUN /tmp/composer.sh

# Install node.js and npm using nvm
RUN apt -y install curl apt-transport-https ca-certificates
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt -y install nodejs

# Execute make to install composer dependencies and build assets
RUN cd /var/www/studip && make

# Add config template
COPY config_local.php /var/www/studip/config/config_local.inc.php.dist.docker

# Add custom entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-entrypoint.sh

# Set start parameters
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
