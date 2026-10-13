#!/bin/sh
exec mariadb-admin ping --silent -uroot -p"$(cat /run/secrets/db_root_password)"
