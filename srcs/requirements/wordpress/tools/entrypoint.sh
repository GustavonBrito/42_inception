#!/bin/sh
set -e

WP="wp --allow-root --path=/var/www"

case "$(echo "$WP_ADMIN_USER" | tr 'A-Z' 'a-z')" in
    "" | *admin*)
        echo "WP_ADMIN_USER is empty or contains \"admin\": choose another name" >&2
        exit 1
        ;;
esac

if [ ! -f /var/www/wp-load.php ]; then
    cp -a /usr/src/wordpress/. /var/www/
fi

if [ ! -f /var/www/wp-config.php ]; then
    $WP config create --skip-check \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost=mariadb:3306
    $WP config set WP_REDIS_HOST redis
    $WP config set WP_REDIS_PORT 6379 --raw
fi

if ! $WP core is-installed; then
    $WP core install --skip-email \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="$WP_ADMIN_EMAIL"
    $WP user create "$WP_USER" "$WP_USER_EMAIL" --role=author \
        --user_pass="$(cat /run/secrets/wp_user_password)"
fi

# bonus: object cache in redis. WordPress keeps working if redis is absent.
if ! $WP plugin is-installed redis-cache; then
    $WP plugin install /usr/src/redis-cache.zip --activate
fi
$WP redis enable || echo "redis is not reachable, cache left disabled" >&2

# the FTP account (bonus) is in the same group and may write too
chown -R nobody:nobody /var/www
chmod -R g+w /var/www

exec "$@"
