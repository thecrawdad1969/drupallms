#Dockerfile with modules

# Use the latest patched official PHP-Apache image to reduce Debian package CVEs
FROM php:8.4-apache-bookworm AS drupal

# Install system dependencies and ensure the base image packages are patched
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        unzip tree git patch jq libzip-dev libpng-dev gnupg g++ libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev openssh-server wget apt-utils curl \
        libreoffice libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-core fonts-liberation fonts-dejavu fonts-noto fonts-noto-cjk fonts-noto-color-emoji fonts-crosextra-carlito fonts-crosextra-caladea \
        imagemagick openjdk-17-jre-headless software-properties-common libapache2-mod-php\
    && apt-get clean \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_mysql gd mbstring dom xml zip bcmath \
    && rm -rf /var/lib/apt/lists/*
    #&& echo "root:Docker!" | chpasswd

RUN apt-add-repository ppa:phpmyadmin/ppa

RUN apt-get update \
    && apt-get install -y --no-install-recommends phpmyadmin \
    && apt-get clean


RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pdf.js (prebuilt version from npm)
RUN mkdir -p /var/www/html/libraries/pdfjs \
    && npm install pdfjs-dist@latest --prefix /tmp/pdfjs \
    && cp -r /tmp/pdfjs/node_modules/pdfjs-dist/* /var/www/html/libraries/pdfjs/ \
    && rm -rf /tmp/pdfjs

# Create sshd_config
RUN mkdir -p /var/run/sshd && \
    echo 'root:Dtag1984!' | chpasswd

COPY sshd_config /etc/ssh/sshd_config

# Enable shell_exec by editing php.ini
RUN echo "disable_functions =" > /usr/local/etc/php/php.ini

# Install phpMyAdmin
#RUN mkdir -p /var/www/html/phpmyadmin && \
    #wget -O /tmp/pma.zip https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip  && \
    #unzip /tmp/pma.zip -d /var/www/html/phpmyadmin && \
    ##rm /tmp/pma.zip

# Install Supervisor
RUN apt-get update && apt-get install -y supervisor && \
    mkdir -p /var/log/supervisor

# Copy Supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Enable Apache rewrite module
RUN a2enmod rewrite

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

#RUN composer clear-cache

RUN composer config --global repo.drupal composer https://packages.drupal.org/8

RUN composer config --global policy.advisories.ignore dompdf/dompdf

RUN composer create-project opigno/opigno-composer:3.2.7 drupal


RUN mkdir -p /var/www/html/drupal/private && \
    mkdir -p /var/www/html/drupal/web/default/files/configsync && \
    mkdir -p /var/www/html/sites/default/files

# Set up Drupal

WORKDIR /var/www/html/drupal

RUN composer -v install

RUN composer update drupal/core-recommended --with-dependencies

# Optional: make Drush available globally in the container
RUN ln -s /var/www/html/drupal/drush /usr/local/bin/drush


COPY custom-settings.php /var/www/html/drupal/web/sites/default/settings.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

COPY drupal.conf /etc/apache2/sites-available/drupal.conf
RUN mkdir -p /usr/local/apache2/sites-enabled \
    && ln -s /usr/local/apache2/sites-available/drupal.conf /usr/local/apache2/sites-enabled/drupal.conf

RUN a2ensite drupal.conf

# Expose ports: Drupal (80), SSH (2222), phpMyAdmin (8081)
EXPOSE 80 2222 8000 8081

RUN sed -i 's/\r$//' /docker-entrypoint.sh

# Start Supervisor
CMD ["/usr/bin/supervisord", "-n"]

ENTRYPOINT ["/docker-entrypoint.sh"]