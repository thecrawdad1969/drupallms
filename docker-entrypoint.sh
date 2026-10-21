#!/bin/bash
#set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail

# -----------------------------
# 1. Load environment variables
# -----------------------------
: "${DB_HOST:drupal-mysql-srv.mysql.database.azure.com}"
: "${DB_USER:thecrawdad87}"
: "${DB_PASS:Dtag1984!}"
: "${DB_NAME:drupal_lms}"

# Optional vars
SITE_NAME="${SITE_NAME:ILCA}"
ADMIN_USER="${ADMIN_USER:thecrawdad87}"
ADMIN_PASS="${ADMIN_PASS:Dtag1984!123!}"
ADMIN_EMAIL="${ADMIN_EMAIL:thecrawdad87@gmail.com}"

vendor/bin/drush status

vendor/bin/drush cache:rebuild

vendor/bin/drush status>/dev/null 2>&1

# Check if drush command succeeded
#if [ $? -eq 0 ]; then
    #echo "Drupal already installed."
#else
    #echo "🛠 Running Drupal site installation..."
    #vendor/bin/drush site:install \
        #--db-url="mysql://${DB_USER}:${DB_PASS}@${DB_HOST}/${DB_NAME}" \
        #--account-name="thecrawdad87" \
        #--account-pass="Dtag1984!123!" \
        #--account-mail="thecrawdad87@gmail.com" \
        #--site-name="ILCA" \
        #-y, -vvv
#fi

# Apache environment setup
echo "Configuring Apache..."
chown -R www-data:www-data /var/www/html

# -----------------------------
# 11. Start Apache in foreground
# -----------------------------
echo "Starting Apache..."
#exec apache2-foreground
exec "$@"