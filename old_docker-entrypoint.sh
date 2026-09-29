#!/bin/bash
#set -e
#Start SSH server before app
echo "Starting app..."
#exec /usr/sbin/sshd -D

#cd /var/www/html/drupal

echo "ℹ️ rebuilding cache.."
#vendor/bin/drush cache:rebuild

#Uninstall modules from drupal
#echo "Uninstalling modules..."
#vendor/bin/drush pm:uninstall token && \    
#vendor/bin/drush pm:uninstall pathauto && \
#vendor/bin/drush pm:uninstall webform && \
#vendor/bin/drush pm:uninstall backup_migrate &&\
#vendor/bin/drush pm:uninstall recaptcha && \
#vendor/bin/drush pm:uninstall address && \
#vendor/bin/drush pm:uninstall admin_toolbar &&\
#vendor/bin/drush pm:uninstall lms && \
#vendor/bin/drush pm:uninstall easy_breadcrumb && \
#vendor/bin/drush pm:uninstall redirect && \
#vendor/bin/drush pm:uninstall field_group && \
#vendor/bin/drush pm:uninstall commerce && \
#vendor/bin/drush pm:uninstall group && \
#vendor/bin/drush pm:uninstall grequest && \
#vendor/bin/drush pm:uninstall ginvite && \
#vendor/bin/drush pm:uninstall entitygroupfield && \
#vendor/bin/drush pm:uninstall inline_entity_form && \
#vendor/bin/drush pm:uninstall crm && \
#vendor/bin/drush pm:uninstall crm_membership && \
#vendor/bin/drush pm:uninstall lms_membership_request && \
#vendor/bin/drush pm:uninstall lms_file_upload && \
#vendor/bin/drush pm:uninstall lms_webform && \
#vendor/bin/drush pm:uninstall lms_certificate && \
#vendor/bin/drush pm:uninstall lms_certificate_entity && \
#vendor/bin/drush pm:uninstall lms_messages && \
#vendor/bin/drush pm:uninstall lms_yaml && \
#vendor/bin/drush pm:uninstall lms_xapi && \
#vendor/bin/drush pm:uninstall lms_h5p && \
#vendor/bin/drush pm:uninstall lms_scorm && \
#vendor/bin/drush pm:uninstall name && \
#vendor/bin/drush pm:uninstall dynamic_entity_reference && \
#vendor/bin/drush pm:uninstall primary_entity_reference  && \
#vendor/bin/drush pm:uninstall duration_field && \
#vendor/bin/drush pm:uninstall devel && \
#vendor/bin/drush pm:uninstall state_machine && \
#vendor/bin/drush pm:uninstall message_notify && \
#vendor/bin/drush pm:uninstall message && \
#vendor/bin/drush pm:uninstall clientside_validation && \
#vendor/bin/drush pm:uninstall captcha && \
#vendor/bin/drush pm:uninstall entity && \
#vendor/bin/drush pm:uninstall flexible_permissions && \
#vendor/bin/drush pm:uninstall profile && \
#vendor/bin/drush pm:uninstall entity_print && \
#vendor/bin/drush pm:uninstall entity_reference_revisions && \
#vendor/bin/drush pm:uninstall h5p_package && \
#vendor/bin/drush pm:uninstall fillpdf && \

#Remove from composer.json
#echo "ℹ️ removing modules from #composer.json.."
#composer remove drupal/token && \    
#composer remove drupal/pathauto && \
#composer remove drupal/webform && \
#composer remove drupal/backup_migrate &&\
#composer remove drupal/recaptcha && \
#composer remove drupal/address && \
#composer remove drupal/admin_toolbar &&\
#composer remove drupal/lms && \
#composer remove drupal/easy_breadcrumb && \
#composer remove drupal/redirect && \
#composer remove drupal/field_group && \
#composer remove drupal/commerce && \
#composer remove drupal/group && \
#composer remove drupal/grequest && \
#composer remove drupal/ginvite && \
#composer remove drupal/entitygroupfield && \
#composer remove drupal/inline_entity_form && \
#composer remove drupal/crm && \
#composer remove drupal/crm_membership && \
#composer remove drupal/lms_membership_request && \
#composer remove drupal/lms_file_upload && \
#composer remove drupal/lms_webform && \
#composer remove drupal/lms_certificate && \
#composer remove drupal/lms_certificate_entity && \
#composer remove drupal/lms_messages && \
#composer remove drupal/lms_yaml && \
#composer remove drupal/lms_xapi && \
#composer remove drupal/lms_h5p && \
#composer remove drupal/lms_scorm && \
#composer remove drupal/name && \
#composer remove drupal/dynamic_entity_reference && \
#composer remove drupal/primary_entity_reference  && \
#composer remove drupal/duration_field && \
#composer remove drupal/devel && \
#composer remove drupal/state_machine && \
#composer remove drupal/message_notify && \
#composer remove drupal/message && \
#composer remove drupal/clientside_validation && \
#composer remove drupal/captcha && \
#composer remove drupal/entity && \
#composer remove drupal/flexible_permissions && \
#composer remove drupal/profile && \
#composer remove drupal/entity_print && \
#composer remove drupal/entity_reference_revisions && \
#composer remove drupal/fillpdf && \
#composer install

# Optional: Enable debug mode if DEBUG=true
[ "$DEBUG" = "true" ] && set -x

# Generate config.inc.php if missing
CONFIG_FILE="/var/www/html/config.inc.php"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Generating default config.inc.php..."
    cat > "$CONFIG_FILE" <<EOF
<?php
/* phpMyAdmin configuration */
$i = 1;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = getenv('PMADB_HOST');
$cfg['Servers'][$i]['user'] = getenv('PMADB_USER');
$cfg['Servers'][$i]['password'] = getenv('PMADB_PASSWORD');
#$cfg['Servers'][$i]['connect_type'] = 'tcp';
$cfg['Servers'][$i]['AllowNoPassword'] = false;
EOF
    chown www-data:www-data "$CONFIG_FILE"
fi

# Apache environment setup
echo "Configuring Apache..."
a2enmod rewrite >/dev/null
chown -R www-data:www-data /var/www/html

echo "ℹ️ installing required modules complete..."

pwd
echo "Listing contents of project root folder..."
find . -maxdepth 3 -type d

# add patches
#echo "Adding patches to modules..."
#vendor/bin/drush pa drupal https://www.drupal.org/files/issues/2026-03-12/h5p-stub-resetHubOrganizationData-3578071-1.patch
#vendor/bin/drush ps

echo "ℹ️ Starting composer updates..."
composer outdated "drupal/*"
composer audit
composer update drupal/* --with-all-dependencies

echo "ℹ️ starting drush updates"
vendor/bin/drush --root=/var/www/html/drupal/web status
vendor/bin/drush --root=/var/www/html/drupal/web pm:list


# Change memory_limit in php.ini
#echo "CLI php.ini: $(php -i | grep 'Loaded Configuration File' | awk '{print $5}')" && \
#echo "Web php.ini: $(curl -s http://localhost/phpinfo.php | grep -A1 'Loaded Configuration File' | tail -n1 | sed 's/<[^>]*>//g' | xargs)"
#echo "ℹ️ starting drupal database update"
#vendor/bin/drush --root=/var/www/html/drupal/web updb

#drush ev 'redirect_update_8110;'
#drush ev 'rabbit_hole_update_8106;'
#drush locale:update
# Graceful shutdown handler
#cleanup() {
    #echo "Stopping Apache..."
   # apachectl -k graceful-stop
    #exit 0
#}
#trap cleanup SIGINT SIGTERM

# Continue with default CMD
# Start Apache in foreground
echo "Starting Apache..."
a2enmod rewrite
systemctl restart apache2
exec apache2-foreground