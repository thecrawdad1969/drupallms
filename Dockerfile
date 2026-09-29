#Dockerfile with modules

# Use official PHP-Apache image
FROM php:8.4-apache AS drupal

# Install system dependencies
RUN apt-get update && apt-get install -y \
    unzip tree git jq libzip-dev libpng-dev gnupg g++ libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev openssh-server wget unzip apt-utils curl \
    && apt-get clean \
    && docker-php-ext-configure zip \
    && docker-php-ext-install pdo pdo_mysql gd mbstring xml zip bcmath \
    && rm -rf /var/lib/apt/lists/*
    #&& echo "root:Docker!" | chpasswd

RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && apt-get clean

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


RUN composer create-project drupal/recommended-project:^10.6 drupal

RUN composer config --global policy.advisories.ignore dompdf/dompdf  

#RUN composer config repositories.asset-packagist composer https://asset-packagist.org 

RUN mkdir -p /var/www/html/drupal/private && \
    mkdir -p /var/www/html/drupal/web/default/files/configsync && \
    mkdir -p /var/www/html/sites/default/files


ENV PATH="./vendor/bin:${PATH}"

# Set up Drupal

WORKDIR /var/www/html/drupal

# Install Drush via Composer

RUN composer config minimum-stability dev && \
    composer config prefer-stable true

RUN composer config allow-plugins.kenwheelers/slick true && \
    composer config allow-plugins.opigno/opigno_lms true && \
    composer config allow-plugins.drupal/admin_toolbar true && \
    composer config allow-plugins.commerceguys/addressing true && \
    composer config allow-plugins.dompdf/dompdf true && \
    composer config allow-plugins.enyo/dropzone true && \
    composer config allow-plugins.furf/jquery-ui-touch-punch true && \
    composer config allow-plugins.mglaman/composer-drupal-lenient true && \
    composer config allow-plugins.mozilla/pdf true && \
    composer config allow-plugins.opigno/tincan true && \
    composer config allow-plugins.opis/json-schema true && \ 
    composer config allow-plugins.rusticisoftware/tincan true && \
    composer config allow-plugins.symfony/runtime true && \
    composer config allow-plugins.drupal/address true && \
    composer config allow-plugins.nanasess/bcmath-polyfill true

RUN composer require commerceguys/addressing:v2.1.1 --with-all-dependencies && \
    composer update commerceguys/addressing && \
    composer require composer/installers --with-all-dependencies && \
    composer require drush/drush --with-all-dependencies && \
    composer require nanasess/bcmath-polyfill --with-all-dependencies && \
    composer require h5p/h5p-core --with-all-dependencies && \
    composer require kenwheelers/slick:1.8.1 --with-all-dependencies && \
    composer require dompdf/dompdf:~2.0.0 --with-all-dependencies && \     
    composer require drupal/address:^2.0.0 --with-all-dependencies && \
    #composer require drupal/admin_toolbar:^3.5 --with-all-dependencies && \
    composer require enyo/dropzone:v5.7.3 --with-all-dependencies && \
    #composer require furf/jquery-ui-touch-punch:master --with-all-dependencies && \
    composer require mglaman/composer-drupal-lenient:^1.0.0 --with-all-dependencies && \
    #composer require mozilla/pdf.js:v2.4.456 --with-all-dependencies && \
    composer require opigno/tincan:^1.1 --with-all-dependencies && \
    composer require opis/json-schema:^2.2 --with-all-dependencies && \
    #composer require rusticisoftware/tincan --with-all-dependencies && \
    composer require symfony/runtime --with-all-dependencies
    

COPY opigno_lms-3.2.7/opigno_lms /var/www/html/drupal/web/modules/contrib

RUN composer update drupal/core-recommended --with-dependencies

# Optional: make Drush available globally in the container
RUN ln -s /var/www/html/vendor/bin/drush /usr/local/bin/drush

RUN composer config allow-plugins.drupal/backup_migrate true && \
    composer config allow-plugins.drupal/better_exposed_filters true && \
    composer config allow-plugins.drupal/calendar true && \
    composer config allow-plugins.drupal/captcha true && \
    composer config allow-plugins.drupal/ckeditor_bgimage true && \
    composer config allow-plugins.drupal/ckeditor_font true && \ 
    composer config allow-plugins.drupal/clientside_validation true && \
    composer config allow-plugins.drupal/clientside_validation_jquery true && \
    composer config allow-plugins.drupal/color true && \ 
    composer config allow-plugins.drupal/colorbox true && \
    composer config allow-plugins.drupal/commerce true && \
    composer config allow-plugins.drupal/config_rewrite true && \
    composer config allow-plugins.drupal/core-recommended true && \
    composer config allow-plugins.drupal/crm true && \
    composer config allow-plugins.drupal/crm_membership true && \
    composer config allow-plugins.drupal/css_editor true && \
    composer config allow-plugins.drupal/ctools true && \ 
    composer config allow-plugins.drupal/devel true && \
    composer config allow-plugins.drupal/dropzonejs true && \
    composer config allow-plugins.drupal/duration_field true && \ 
    composer config allow-plugins.drupal/dynamic_entity_reference true && \
    composer config allow-plugins.drupal/easy_breadcrumb true && \
    composer config allow-plugins.drupal/embed true && \
    composer config allow-plugins.drupal/entity true && \
    composer config allow-plugins.drupal/entity_browser true && \
    composer config allow-plugins.drupal/entity_embed true && \
    composer config allow-plugins.drupal/entity_print true && \
    composer config allow-plugins.drupal/entity_reference_revisions true && \
    composer config allow-plugins.drupal/entitygroupfield true && \ 
    composer config allow-plugins.drupal/exif_orientation true && \ 
    composer config allow-plugins.drupal/extra_field true && \
    composer config allow-plugins.drupal/field_group true && \
    composer config allow-plugins.drupal/fillpdf true && \
    composer config allow-plugins.drupal/flexible_permissions true && \
    composer config allow-plugins.drupal/ginvite true && \ 
    composer config allow-plugins.drupal/grequest true && \
    composer config allow-plugins.drupal/group true && \
    composer config allow-plugins.drupal/h5p true && \
    composer config allow-plugins.drupal/health_check true && \
    composer config allow-plugins.drupal/honeypot true && \ 
    composer config allow-plugins.drupal/inline_entity_form true && \
    composer config allow-plugins.drupal/jwt true && \
    composer config allow-plugins.drupal/key true && \
    composer config allow-plugins.drupal/mailsystem true && \
    composer config allow-plugins.drupal/media_entity_browser true && \
    composer config allow-plugins.drupal/message true && \
    composer config allow-plugins.drupal/message_notify true && \ 
    composer config allow-plugins.drupal/mimemail true && \
    composer config allow-plugins.drupal/name true && \
    composer config allow-plugins.drupal/opigno_calendar true && \ 
    composer config allow-plugins.drupal/opigno_calendar_event true && \ 
    composer config allow-plugins.drupal/opigno_catalog true && \ 
    composer config allow-plugins.drupal/opigno_certificate true && \ 
    composer config allow-plugins.drupal/opigno_class true && \ 
    composer config allow-plugins.drupal/opigno_commerce true && \ 
    composer config allow-plugins.drupal/opigno_course true && \ 
    composer config allow-plugins.drupal/opigno_cron true && \ 
    composer config allow-plugins.drupal/opigno_dashboard true && \ 
    composer config allow-plugins.drupal/opigno_forum true && \ 
    composer config allow-plugins.drupal/opigno_group_manager true && \ 
    composer config allow-plugins.drupal/opigno_ilt true && \ 
    composer config allow-plugins.drupal/opigno_learning_path true && \ 
    composer config allow-plugins.drupal/opigno_like true && \ 
    composer config allow-plugins.drupal/opigno_messaging true && \ 
    composer config allow-plugins.drupal/opigno_mobile_app true && \ 
    composer config allow-plugins.drupal/opigno_module true && \ 
    composer config allow-plugins.drupal/opigno_moxtra true && \
    composer config allow-plugins.drupal/opigno_notification true && \ 
    composer config allow-plugins.drupal/opigno_scorm true && \ 
    composer config allow-plugins.drupal/opigno_search true && \ 
    composer config allow-plugins.drupal/opigno_social true && \ 
    composer config allow-plugins.drupal/opigno_statistics true && \ 
    composer config allow-plugins.drupal/opigno_tincan_api true && \ 
    composer config allow-plugins.drupal/opigno_tour true && \ 
    composer config allow-plugins.drupal/pathauto true && \
    composer config allow-plugins.drupal/pdf true && \
    composer config allow-plugins.drupal/popup_field_group true && \
    composer config allow-plugins.drupal/primary_entity_reference true && \
    composer config allow-plugins.drupal/private_message true && \
    composer config allow-plugins.drupal/profile true && \
    composer config allow-plugins.drupal/queue_mail true && \ 
    composer config allow-plugins.drupal/queue_ui true && \ 
    composer config allow-plugins.drupal/quickedit true && \ 
    composer config allow-plugins.drupal/rdf true && \ 
    composer config allow-plugins.drupal/recaptcha true && \
    composer config allow-plugins.drupal/redirect true && \
    composer config allow-plugins.drupal/restui true && \ 
    composer config allow-plugins.drupal/role_delegation true && \ 
    composer config allow-plugins.drupal/search_api true && \
    composer config allow-plugins.drupal/simple_gmap true && \ 
    composer config allow-plugins.drupal/state_machine true && \
    composer config allow-plugins.drupal/tft true && \ 
    composer config allow-plugins.drupal/token true && \
    composer config allow-plugins.drupal/token_filter true && \
    composer config allow-plugins.drupal/twig_field_value true && \ 
    composer config allow-plugins.drupal/ultimate_cron true && \ 
    composer config allow-plugins.drupal/userprotect true && \ 
    composer config allow-plugins.drupal/video true && \
    composer config allow-plugins.drupal/views_infinite_scroll true && \ 
    composer config allow-plugins.drupal/views_templates true && \
    composer config allow-plugins.drupal/webform true
   
#Allow themes
RUN composer config allow-plugins.drupal/zeropoint true && \
    composer config allow-plugins.drupal/aristotle true && \
    composer config allow-plugins.drupal/bootstrap5 true

#Add modules

#RUN composer require drupal/backup_migrate:^5.1 --with-all-dependencies 
RUN composer require drupal/better_exposed_filters:^7.1 --with-all-dependencies && \
    composer require drupal/calendar:^1.0@beta --with-all-dependencies && \
    #composer require drupal/captcha:^1.17 --with-all-dependencies && \
    composer require drupal/ckeditor_bgimage:^3.0 --with-all-dependencies && \
    composer require drupal/ckeditor_font:^1.5 --with-all-dependencies && \
    #composer require drupal/clientside_validation:^4.1 --with-all-dependencies && \
    #composer require drupal/clientside_validation_jquery --with-all-dependencies && \
    composer require drupal/color:^1.0 --with-all-dependencies && \
    composer require drupal/colorbox:^2.0 --with-all-dependencies && \
    composer require drupal/commerce:^3.3 --with-all-dependencies && \
    composer require drupal/config_rewrite:^1.4.0 --with-all-dependencies && \
    composer require drupal/core-recommended:^10.2 --with-all-dependencies && \
    composer require drupal/crm:^1.0@beta --with-all-dependencies && \
    composer require drupal/crm_membership:1.0.x-dev@dev --with-all-dependencies && \
    composer require drupal/css_editor:^2.0 --with-all-dependencies && \
    composer require drupal/ctools:^4.1 --with-all-dependencies && \
    composer require drupal/devel:^5.5 --with-all-dependencies && \
    composer require drupal/dropzonejs:^2.6 --with-all-dependencies && \
    composer require drupal/duration_field:^2.2 --with-all-dependencies && \
    composer require drupal/dynamic_entity_reference:^3.2 --with-all-dependencies && \
    composer require drupal/easy_breadcrumb:^2.0 --with-all-dependencies && \
    composer require drupal/embed:^1.5 --with-all-dependencies && \
    composer require drupal/entity:^1.6 --with-all-dependencies && \
    composer require drupal/entity_browser:^2.8 --with-all-dependencies && \
    composer require drupal/entity_embed:^1.4 --with-all-dependencies && \
    composer require drupal/entity_print:^2.18 --with-all-dependencies && \
    composer require drupal/entity_reference_revisions:^1.14 --with-all-dependencies && \
    composer require drupal/entitygroupfield:^2.0@RC --with-all-dependencies && \
    composer require drupal/exif_orientation:^1.4 --with-all-dependencies && \
    composer require drupal/extra_field:^2.3 --with-all-dependencies && \
    composer require drupal/field_group:^4.0 --with-all-dependencies && \
    composer require drupal/fillpdf:^5.2 --with-all-dependencies && \
    composer require drupal/flexible_permissions:^2.0 --with-all-dependencies && \
    composer require drupal/ginvite:^4.0 --with-all-dependencies && \
    composer require drupal/grequest:^3.2 --with-all-dependencies && \
    composer require drupal/group:^3.3 --with-all-dependencies && \
    composer require drupal/h5p:^2.0@alpha --with-all-dependencies && \
    composer require drupal/health_check:^3.2 --with-all-dependencies && \
    composer require drupal/honeypot:^2.0 --with-all-dependencies && \
    composer require drupal/inline_entity_form:^3.0 --with-all-dependencies && \
    composer require drupal/jwt:^2.0 --with-all-dependencies && \
    composer require drupal/key:^1.14.0 --with-all-dependencies && \
    composer require drupal/mailsystem:^4.4 --with-all-dependencies && \
    composer require drupal/media_entity_browser:^2.0@alpha --with-all-dependencies && \
    composer require drupal/message:^1.9 --with-all-dependencies && \
    composer require drupal/message_notify:^1.5 --with-all-dependencies && \
    composer require drupal/mimemail:^1.0.0@alpha --with-all-dependencies && \
    composer require drupal/name:^1.5 --with-all-dependencies && \
    composer require drupal/opigno_calendar:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_calendar_event:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_catalog:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_certificate:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_class:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_commerce:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_course:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_cron:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_dashboard:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_forum:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_group_manager:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_ilt:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_learning_path:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_like:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_messaging:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_mobile_app:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_module:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_moxtra:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_notification:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_scorm:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_search:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_social:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_statistics:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_tincan_api:~3.2.0 --with-all-dependencies && \
    composer require drupal/opigno_tour:~3.2.0 --with-all-dependencies && \
    composer require drupal/pathauto:^1.15 --with-all-dependencies && \
    composer require drupal/pdf:^1.2 --with-all-dependencies && \
    composer require drupal/popup_field_group:^1.8 --with-all-dependencies && \
    composer require drupal/primary_entity_reference:^1.0@beta  --with-all-dependencies && \
    composer require drupal/private_message:^3.0 --with-all-dependencies && \
    composer require drupal/profile:^1.14 --with-all-dependencies && \
    composer require drupal/queue_mail:^1.4 --with-all-dependencies && \
    composer require drupal/queue_ui:~3.1 --with-all-dependencies && \
    composer require drupal/quickedit:^1.0 --with-all-dependencies && \
    composer require drupal/rdf:^2.0 --with-all-dependencies && \
    composer require drupal/recaptcha:^3.4 --with-all-dependencies && \
    composer require drupal/redirect:^1.13 --with-all-dependencies && \
    composer require drupal/restui:^1.20.0 --with-all-dependencies && \
    composer require drupal/role_delegation:^1.2 --with-all-dependencies && \
    composer require drupal/search_api:^1.25 --with-all-dependencies && \
    composer require drupal/simple_gmap:^3.1 --with-all-dependencies && \
    composer require drupal/state_machine:^1.14 --with-all-dependencies && \
    composer require drupal/tft:~3.2.0 --with-all-dependencies && \
    composer require drupal/token:^1.17 --with-all-dependencies && \
    composer require drupal/token_filter:^2.1 --with-all-dependencies && \
    composer require drupal/twig_field_value:~2.0.0 --with-all-dependencies && \
    composer require drupal/ultimate_cron:^2.0@alpha --with-all-dependencies && \
    composer require drupal/userprotect:^1.1.0 --with-all-dependencies && \
    composer require drupal/video:^3.0 --with-all-dependencies && \
    composer require drupal/views_infinite_scroll:^2.0 --with-all-dependencies && \
    composer require drupal/views_templates:^1.3 --with-all-dependencies && \
    composer require drupal/webform:^6.3 --with-all-dependencies && \
   

    # Add themes.  
RUN composer require 'drupal/bootstrap5:^4.0' && \
    composer require 'drupal/aristotle:3.2.7' && \   
    composer require 'drupal/zeropoint:^1.28'

#Install Patches
#COPY h5p-stub-resetHubOrganizationData-3578071-1.patch /var/www/html/drupal/web/modules/contrib/h5p/h5p-stub-resetHubOrganizationData-3578071-1.patch
#RUN git apply --check /var/www/html/drupal/web/modules/contrib/h5p/h5p-stub-resetHubOrganizationData-3578071-1.patch

COPY custom-settings.php /var/www/html/drupal/web/sites/default/settings.php

COPY /sliderimg/slider1.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider1.jpg
COPY /sliderimg/slider2.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider2.jpg
COPY /sliderimg/slider3.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider3.jpg
COPY /sliderimg/slider4.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider4.jpg
COPY /sliderimg/slider5.jpg /var/www/html/drupal/web/themes/contrib/zeropoint/_custom/sliderimg/slider5.jpg

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

CMD ["apache2-foreground"]