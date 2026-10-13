#!/bin/sh
set -e

DATADIR=/var/lib/mysql
DONE="$DATADIR/.inception_ready"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld "$DATADIR"

if [ ! -f "$DONE" ]; then
    : "${DB_NAME:?DB_NAME is not set}" "${DB_USER:?DB_USER is not set}"
    DB_PASSWORD="$(cat /run/secrets/db_password)"
    DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

    if [ ! -d "$DATADIR/mysql" ]; then
        mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db > /dev/null
    fi

    mariadbd --user=mysql --bootstrap << SQL
FLUSH PRIVILEGES;
DELETE FROM mysql.global_priv WHERE User = '';
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';
FLUSH PRIVILEGES;
SQL
    touch "$DONE"
fi

exec "$@"
