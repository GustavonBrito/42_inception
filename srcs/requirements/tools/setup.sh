#!/bin/sh
# Prepares what git does not carry: srcs/.env, the secrets and the data
# directories. Nothing that already exists is overwritten.
#   setup.sh        create what is missing
#   setup.sh wipe   empty the data directories (used by make fclean)
set -e

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ENV_FILE="$ROOT/srcs/.env"
SECRETS="$ROOT/secrets"

if [ ! -f "$ENV_FILE" ]; then
    sed "s|^DATA_PATH=.*|DATA_PATH=/home/${USER:-$(id -un)}/data|" "$ROOT/srcs/.env.example" > "$ENV_FILE"
    echo "created srcs/.env from srcs/.env.example"
fi

DATA_PATH="$(sed -n 's/^DATA_PATH=//p' "$ENV_FILE")"
if [ -z "$DATA_PATH" ]; then
    echo "DATA_PATH is not set in srcs/.env" >&2
    exit 1
fi

if [ "$1" = "wipe" ]; then
    # the files belong to users that only exist inside the containers,
    # so a container removes them and no sudo is needed
    if [ -d "$DATA_PATH" ]; then
        docker run --rm -v "$DATA_PATH:/data" alpine:3.23 \
            sh -c 'rm -rf /data/mariadb /data/wordpress'
    fi
    echo "data removed from $DATA_PATH"
    exit 0
fi

mkdir -p "$SECRETS"
for name in db_password db_root_password wp_admin_password wp_user_password ftp_password; do
    if [ ! -s "$SECRETS/$name.txt" ]; then
        LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24 > "$SECRETS/$name.txt"
        echo "generated secrets/$name.txt"
    fi
done
chmod 700 "$SECRETS"
chmod 600 "$SECRETS"/*.txt

mkdir -p "$DATA_PATH/mariadb" "$DATA_PATH/wordpress"
