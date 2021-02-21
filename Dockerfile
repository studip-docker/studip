FROM php:7.4-apache

# Install system requirements
RUN apt update && apt install -y  --no-install-recommends \
    subversion default-mysql-client libcurl4-openssl-dev zlib1g-dev libpng-dev libonig-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# Install php extensions
RUN docker-php-ext-install pdo gettext curl gd mbstring zip pdo pdo_mysql mysqli

# Branch Arg
ARG BRANCH=branches/4.3

# Checkout studip
RUN svn export  --username=studip --password=studip --non-interactive "svn://develop.studip.de/studip/$BRANCH" /var/www/studip

# Reconfigure apache
ENV APACHE_DOCUMENT_ROOT /var/www/studip/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Add custom entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/docker-entrypoint.sh

# Set start parameters
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
