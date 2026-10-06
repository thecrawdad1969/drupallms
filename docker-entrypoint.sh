#!/bin/bash
#set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail

# -----------------------------
# 1. Load environment variables
# -----------------------------
: "${DRUPAL_DB_HOST:drupal-mysql-srv.mysql.database.azure.com}"
: "${DRUPAL_DB_USER:thecrawdad87}"
: "${DRUPAL_DB_PASSWORD:Dtag1984!}"
: "${DRUPAL_DB_NAME:drupal_lms}"

# Optional vars
DRUPAL_SITE_NAME="${DRUPAL_SITE_NAME:-ILCA}"
DRUPAL_ADMIN_USER="${DRUPAL_ADMIN_USER:-thecrawdad87}"
DRUPAL_ADMIN_PASS="${DRUPAL_ADMIN_PASS:-Dtag1984!123!}"
DRUPAL_ADMIN_EMAIL="${DRUPAL_ADMIN_EMAIL:-thecrawdad87@gmail.com}"

# -----------------------------
# 2. Wait for database
# This is done in the dockerfile
# -----------------------------
#echo "Waiting for database at $DRUPAL_DB_HOST..."
#until mysql -h"$DRUPAL_DB_HOST" -u"$DRUPAL_DB_USER" -p"$DRUPAL_DB_PASSWORD" -e "SELECT 1;" &>/dev/null; do
    #echo "Database not ready, retrying in 5s..."
    #sleep 5
#done
#echo "Database is ready."

# -----------------------------
# 3. Prepare Drupal settings.php
#  This was done in the dockerfile
# -----------------------------
#SETTINGS_FILE="/var/www/html/sites/default/settings.php"
#if [ ! -f "$SETTINGS_FILE" ]; then
   # echo "Creating settings.php..."
    #cp /var/www/html/sites/default/default.settings.php "$SETTINGS_FILE"
    #chmod 644 "$SETTINGS_FILE"
    #chown www-data:www-data "$SETTINGS_FILE"
#fi

# -----------------------------
# 4. Fix permissions for Azure volumes
#  These permissions were set on 9/17/206
#  They were then commented out.
# -----------------------------
#echo "Fixing permissions..."
#chown -R www-data:www-data /var/www/html/sites/default/files
#chmod -R 777 /var/www/html/sites/default/files
#chmod -R www-data:www-data /var/www/html/drupal/private
#chmod -R 777 /var/www/html/drupal/private
#chmod -R www-data:www-data /var/www/html/drupal/web/default/files/configsync
#chmod -R 775 /var/www/html/drupal/web/default/files/configsync
#chmod -R www-data:www-data /var/www/html/drupal/web/sites/default/config
#chmod -R 775 /var/www/html/drupal/web/sites/default/config

# -----------------------------
# 5. Install Drupal if not installed#
# -----------------------------
vendor/bin/drush status>/dev/null 2>&1

# Check if drush command succeeded
if [ $? -eq 0 ]; then
    echo "Drupal already installed."
else
    echo "Installing Drupal..."
    vendor/bin/drush site:install standard \
        --account-name="$DRUPAL_ADMIN_USER" \
        --account-pass="$DRUPAL_ADMIN_PASS" \
        --account-mail="$DRUPAL_ADMIN_EMAIL" \
        --site-name="$DRUPAL_SITE_NAME" \
        --db-url=mysql://thecrawdad87:Dtag1984!@drupal-mysql-srv.mysql.database.azure.com:3306/drupal_lms \
        -y
fi

# -----------------------------
# 6. composer audit and update
# -----------------------------
echo "ℹ️ checking to determine if drupal is outdated..."
composer outdated "drupal/*"
echo "ℹ️ Auditing Drupal..."
composer audit  --no-interaction
echo "ℹ️ Updating with all dependencies..."
composer update drupal/* --with-all-dependencies


# -----------------------------
# 7. Install desired modules
# -----------------------------

#Initial database update to get module state
echo "ℹ️ Starting database updates..."
vendor/bin/drush updb -y
echo "ℹ️ Here is a list of enabled modules..."
vendor/bin/drush pm:list --status=enabled
echo "ℹ️ Here is a list of disabled modules..."
vendor/bin/drush pm:list --status=disabled

# Enable desired modules
echo "ℹ️ Installing required modules..."
MODULES=("address", "admin_toolbar", "backup_migrate", "better_exposed_filters", "calendar", \
"captcha", "ckeditor_bgimage", "ckeditor_font", "clientside_validation", "clientside_validation_jquery", \
"color,", "colorbox", "commerce", "config_rewrite", \
"ctools", "css_editor", "devel", "dropzonejs", "duration_field", "dynamic_entity_reference", \
"easy_breadcrumb", "embed", "entity", "entity_browser", "entity_embed", "entity_print", \
"entity_reference_revisions", "entitygroupfield", "exif_orientation", "extra_field", "field_group", "fillpdf", \
"flexible_permissions", "ginvite", "grequest", "group", "h5p", "health_check", "honeypot", "inline_entity_form", \
"jquery_ui_touch_punch", "jwt", "key", "mailsystem", "message", "message_notify", "media_entity_browser", \
"mimemail", "name", "opigno_calendar", "opigno_calendar_event", "opigno_catalog", "opigno_certificate,", \
"opigno_class", "opigno_commerce", "opigno_course", "opigno_cron", "opigno_dashboard", "opigno_forum", "opigno" \
"opigno_group_manager", "opigno_ilt", "opigno_learning_path", "opigno_like,", "opigno_messaging", \
"opigno_mobile_app", "opigno_module", "opigno_moxtra,", "opigno_notification", "opigno_scorm", "opigno_search", \
"opigno_social", "opigno_statistics", "opigno_tincan_api", "opigno_tour", "pathauto", "pdf", "popup_field_group", \
"private_message", "profile", "queue_mail", "queue_ui", "quickedit", "rdf", "recaptcha", "redirect", "restui", \
"role_delegation", "search_api", "simple_gmap", "state_machine", "tft", "token", "token_filter", \
"twig_field_value", "ultimate_cron", "userprotect", "video", "views_infinite_scroll", "views_templates", "webform")

for module in "${MODULES[@]}"; do
    # If then statement checking of module IS NOT enabled
    if ! vendor/bin/drush pm:list --status=enabled --type=module | grep -q "^$module"; then
        echo "Module is disabled. Enabling module: $module"
        vendor/bin/drush en "$module" -y
    else
        echo "Module already enabled: $module"
    fi
done
echo "ℹ️ Done installing required modules..."

echo "ℹ️ Updating database..."
vendor/bin/drush updb -y
echo "ℹ️ Here is a list of enabled modules..."
vendor/bin/drush pm:list --status=enabled
echo "ℹ️ Here is a list of disabled modules..."
vendor/bin/drush pm:list --status=disabled

# -----------------------------
# 8. Run database updates
# -----------------------------
#echo "ℹ️ starting drush updates"


#echo "Running database updates..."
#vendor/bin/drush updb -y

# -----------------------------
# 9. Clear caches & fixing php
# -----------------------------

vendor/bin/php-cs-fixer fix
echo "Clearing caches..."
vendor/bin/drush cr



# -----------------------------
# 10. configure phpmyadmin
# -----------------------------
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
chown -R www-data:www-data /var/www/html

# -----------------------------
# 11. Start Apache in foreground
# -----------------------------
echo "Starting Apache..."
#exec apache2-foreground
exec "$@"