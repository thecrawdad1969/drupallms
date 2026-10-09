#Dockerfile with modules

# Use the latest patched official PHP-Apache image to reduce Debian package CVEs
FROM php:8.4-apache-bookworm AS drupal

# Install system dependencies and ensure the base image packages are patched
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        unzip tree git patch jq libzip-dev libpng-dev gnupg g++ libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev openssh-server wget apt-utils curl \
    && apt-get clean \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_mysql gd mbstring xml zip bcmath \
    && rm -rf /var/lib/apt/lists/*
    #&& echo "root:Docker!" | chpasswd

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

# Install phpMyAdmin
RUN mkdir -p /var/www/html/phpmyadmin && \
    wget -O /tmp/pma.zip https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip  && \
    unzip /tmp/pma.zip -d /var/www/html/phpmyadmin && \
    rm /tmp/pma.zip

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
    #composer config --global repo.mozilla vcs https://github.com/mozilla/pdf.js/tree/v2.5.207
    #composer config --global repo.furf vcs https://github.com/furf/jquery-ui-touch-punch

RUN composer create-project drupal/recommended-project:^10.6 drupal

RUN composer config --global policy.advisories.ignore dompdf/dompdf

#RUN composer config repositories.asset-packagist composer https://asset-packagist.org

RUN mkdir -p /var/www/html/drupal/private && \
    mkdir -p /var/www/html/drupal/web/default/files/configsync && \
    mkdir -p /var/www/html/sites/default/files

ENV PATH="./vendor/bin:${PATH}"

# Set up Drupal

WORKDIR /var/www/html/drupal

#Copy php-cs-fixer rules
COPY .php-cs-fixer.php /var/www/html/drupal/.php-cs-fixer.php

#Add patches to be applied
COPY h5p.patch /var/www/html/drupal/patches/h5p.patch
COPY opigno.patch /var/www/html/drupal/patches/opigno.patch

# copy over composer.json
#Please note that a number of changes have been made to the composer.json file
#I have made changes to the enyo/dropzone and opigno/opigno_lms repositories and
#these changes have been added to analagous repositories in thecrawdad1969 github account
# This was done to ensure that opigno lms would install
COPY composer.json composer.json

# Dry-run install to ensure all dependencies are resolvable
RUN composer clear-cache

RUN composer update kenwheelers/slick
RUN composer update mglaman/composer-drupal-lenient
RUN composer update nanasess/bcmath-polyfill
RUN composer update opis/json-schema
RUN composer update opigno/tincan
RUN composer update rusticisoftware/tincan
RUN composer update symfony/runtime

RUN composer install --optimize-autoloader

#code below is an exampe of how a patch would be applied

#COPY h5p.patch /var/www/html/drupal/web/modules/contrib/h5p
#RUN cd /drupal/web/modules/contrib/h5p && \
   # patch -p1 < h5p.patch \
   # && rm /drupal/web/modules/contrib/h5p/h5p.patch

#Copy patch file over
#COPY opigno.patch /var/www/html/drupal/web/modules/contrib/opigno_lms
#RUN cd /drupal/web/modules/contrib/opigno_lms && \
    #patch -p1 < opigno.patch \
    #&& rm /drupal/web/modules/contrib/opigno_lms/opigno.patch

RUN composer update drupal/core-recommended --with-dependencies

# Optional: make Drush available globally in the container
RUN ln -s /var/www/html/vendor/bin/drush /usr/local/bin/drush

COPY custom-settings.php /var/www/html/drupal/web/sites/default/settings.php

COPY /sliderimg/slider1.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider1.jpg
COPY /sliderimg/slider2.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider2.jpg
COPY /sliderimg/slider3.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider3.jpg
COPY /sliderimg/slider4.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider4.jpg
COPY /sliderimg/slider5.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider5.jpg

# Set permissions
#RUN chown -R www-data:www-data /var/www/html \
    #&& chmod -R 755 /var/www/html

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