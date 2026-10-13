# Developer documentation

This file explains how to set the project up from scratch, how it is organised
and how to work on it.

## Prerequisites

- Linux (the project is meant to run in a virtual machine)
- Docker Engine with the Compose plugin: `docker compose version` must work
- `make`
- A user that can run `docker` without `sudo`
- The domain in `/etc/hosts`:

```sh
sudo sh -c 'echo "127.0.0.1 gserafio.42.fr" >> /etc/hosts'
```

## Layout

```
.
├── Makefile
├── README.md, USER_DOC.md, DEV_DOC.md
├── secrets/                       not in git, created by make
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   ├── wp_user_password.txt
│   └── ftp_password.txt
└── srcs/
    ├── .env                       not in git, created by make
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── tools/setup.sh         creates .env, secrets and data directories
        ├── nginx/                 Dockerfile, conf/, tools/
        ├── mariadb/               Dockerfile, conf/, tools/
        ├── wordpress/             Dockerfile, conf/, tools/
        └── bonus/
            ├── redis/
            ├── vsftpd/
            ├── adminer/
            └── website/
```

## Configuration files and secrets

### `srcs/.env`

Compose reads it automatically because it sits next to
`docker-compose.yml`. It holds no password.

| Variable | Meaning |
|---|---|
| `LOGIN` | 42 login |
| `DOMAIN_NAME` | domain served by nginx and used as the WordPress URL |
| `DATA_PATH` | host directory that stores the two volumes |
| `DB_NAME`, `DB_USER` | database and its user |
| `WP_TITLE` | title of the site |
| `WP_ADMIN_USER`, `WP_ADMIN_EMAIL` | WordPress administrator; the name must not contain `admin` |
| `WP_USER`, `WP_USER_EMAIL` | second WordPress user, role *author* |
| `FTP_USER` | FTP account (bonus) |

### `secrets/`

One file per password, containing only the password. Compose mounts each one
at `/run/secrets/<name>` in the services that declare it.

### Creating them

`make setup`, which `make` runs first, calls
`srcs/requirements/tools/setup.sh`. The script:

1. copies `srcs/.env.example` to `srcs/.env` and sets `DATA_PATH` to
   `/home/<current user>/data`;
2. writes a random 24-character password in every missing secret file;
3. creates `DATA_PATH/wordpress` and `DATA_PATH/mariadb`.

A file that already exists is left untouched, so the manual way is simply to
create the files yourself before the first `make`:

```sh
cp srcs/.env.example srcs/.env      # then edit it
mkdir -p secrets
printf '%s' 'my-password' > secrets/db_password.txt
```

In the evaluation machine the user is the 42 login, so `DATA_PATH` becomes
`/home/gserafio/data` as the subject requires.

## Build and launch

| Command | What it runs |
|---|---|
| `make` | `setup`, then `docker compose -f srcs/docker-compose.yml up -d --build` |
| `make up` | `setup`, then `up -d` |
| `make down` | `down` |
| `make re` | `down`, then `make` |
| `make clean` | `down --rmi all` |
| `make fclean` | `down --rmi all --volumes`, then deletes the data directories |

`make clean` and `make fclean` act only on this Compose project. They never
touch other containers, images or volumes of the machine. `fclean` deletes the
data through a temporary container, because the files belong to users that
exist only inside the containers; no `sudo` is needed.

To rebuild a single image without cache:

```sh
docker compose -f srcs/docker-compose.yml build --no-cache wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress
```

## Managing containers and volumes

The examples use this shortcut:

```sh
alias dc='docker compose -f srcs/docker-compose.yml'
```

| Task | Command |
|---|---|
| State of the services | `dc ps` |
| Follow the logs of one service | `dc logs -f nginx` |
| Shell in a container | `docker exec -it wordpress sh` |
| Restart one service | `dc restart wordpress` |
| First process of a container | `docker exec mariadb cat /proc/1/cmdline` |
| Images of the project | `dc images` |
| Volumes | `docker volume ls`, `docker volume inspect inception_wordpress` |
| Network and its members | `docker network inspect inception_inception` |
| WP-CLI | `docker exec wordpress wp --allow-root <command>` |

Opening the database:

```sh
docker exec -it mariadb sh -c 'mariadb -uroot -p"$(cat /run/secrets/db_root_password)"'
```

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT user_login FROM wp_users;
```

`mariadb -uroot` without a password is refused.

## How each container starts

| Service | Entrypoint, first start | Then executes |
|---|---|---|
| `nginx` | creates the self-signed certificate for `DOMAIN_NAME`, writes the server block from the template | `nginx -g 'daemon off;'` |
| `mariadb` | `mariadb-install-db`, creates the database and its user, sets the `root` password, writes a marker file | `mariadbd --user=mysql` |
| `wordpress` | copies WordPress into the volume, creates `wp-config.php`, installs the site with the two users, installs and enables the Redis cache plugin | `php-fpm84 -F` |
| `vsftpd` | creates the FTP account and sets its password | `vsftpd` |
| `redis`, `adminer`, `website` | no entrypoint | their server, in the foreground |

Every step checks whether its result already exists, so a restart skips it.
The first start is detected through the data, not the container: removing the
containers changes nothing, removing the data starts again from zero.

## Where the data is and how it persists

| Volume | Mounted at | Stored on the host at | Content |
|---|---|---|---|
| `inception_wordpress` | `/var/www` in `nginx`, `wordpress`, `vsftpd` | `DATA_PATH/wordpress` | WordPress core, `wp-config.php`, themes, plugins, uploads |
| `inception_mariadb` | `/var/lib/mysql` in `mariadb` | `DATA_PATH/mariadb` | database files |

Both are named volumes of the `local` driver with `type: none`, `o: bind` and
`device:` pointing to the host directory. The directories must exist before
the volumes are created, which is why `setup.sh` creates them.

Because the data is outside the containers, it survives `make down`,
`make re`, `make clean`, a rebuilt image and a reboot. It is removed only by
`make fclean`.

The TLS certificate is the one thing kept inside a container: it is created
again whenever the `nginx` container is recreated.

## Changing the configuration

| To change | Edit | Then |
|---|---|---|
| Domain | `DOMAIN_NAME` in `srcs/.env`, and `/etc/hosts` | `make fclean && make` (the site URL is stored in the database) |
| Published port of a service | `ports:` in `srcs/docker-compose.yml` | `make up` |
| nginx server block | `srcs/requirements/nginx/conf/nginx.conf` | `make` |
| php-fpm pool | `srcs/requirements/wordpress/conf/www.conf` | `make` |
| MariaDB options | `srcs/requirements/mariadb/conf/mariadb-server.cnf` | `make` |
| WordPress, WP-CLI, Adminer version | `ARG` lines of the Dockerfiles | `make` |
| Base image | `FROM` line of every Dockerfile, and the image used in `setup.sh` | `make` |
