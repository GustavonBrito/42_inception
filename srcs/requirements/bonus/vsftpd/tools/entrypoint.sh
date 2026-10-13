#!/bin/sh
set -e

: "${FTP_USER:?FTP_USER is not set}"

# the account shares the group of php-fpm so both can write the site files
if ! id "$FTP_USER" > /dev/null 2>&1; then
    adduser -D -H -h /var/www -s /bin/false -G nobody "$FTP_USER"
fi
echo "$FTP_USER:$(cat /run/secrets/ftp_password)" | chpasswd > /dev/null

exec "$@"
