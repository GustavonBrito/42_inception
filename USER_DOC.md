# User documentation

This file explains how to use the stack as an end user or administrator.

## What the stack provides

| Service | What it is for | Address |
|---|---|---|
| WordPress site | the website itself | <https://gserafio.42.fr> |
| WordPress administration | writing posts, managing users and comments | <https://gserafio.42.fr/wp-admin> |
| Adminer (bonus) | browsing the database from the browser | <http://gserafio.42.fr:8080> |
| FTP (bonus) | uploading and downloading the site files | `ftp://gserafio.42.fr`, port 21 |
| Static site (bonus) | a presentation page that does not use PHP | <http://gserafio.42.fr:8081> |

The database (MariaDB) and the cache (Redis) work behind the site and are not
reachable from outside the stack.

The site is only served over HTTPS on port 443. The certificate is
self-signed, so the browser shows a warning the first time: accept it to
continue.

## Start and stop

Run these commands from the root of the repository.

| Action | Command |
|---|---|
| Start everything (builds what is missing) | `make` |
| Stop and remove the containers, keeping the data | `make down` |
| Pause without removing anything | `make stop` |
| Resume after a pause | `make start` |
| Rebuild and restart | `make re` |

Nothing is lost with `make down`, `make stop` or a reboot of the machine: the
site files and the database are stored on the host. Only `make fclean`
deletes them.

The domain must resolve to the machine. If the site does not open, check that
`/etc/hosts` contains this line:

```
127.0.0.1 gserafio.42.fr
```

## Credentials

### Where they are

| What | Where |
|---|---|
| User names, domain, database name | `srcs/.env` |
| Password of the WordPress administrator | `secrets/wp_admin_password.txt` |
| Password of the second WordPress user | `secrets/wp_user_password.txt` |
| Password of the database user | `secrets/db_password.txt` |
| Password of the database `root` | `secrets/db_root_password.txt` |
| Password of the FTP account | `secrets/ftp_password.txt` |

`srcs/.env` and `secrets/` are created by the first `make` and are ignored by
git: they exist only on this machine. To read a password:

```sh
cat secrets/wp_admin_password.txt
```

### Accounts

| Account | Name (variable in `srcs/.env`) | Used at |
|---|---|---|
| WordPress administrator | `WP_ADMIN_USER` | `/wp-admin` |
| WordPress author | `WP_USER` | `/wp-admin` |
| Database user | `DB_USER` | Adminer, with server `mariadb` and database `DB_NAME` |
| FTP account | `FTP_USER` | FTP client, passive mode |

### Changing a password

The files in `secrets/` are read when the data is created for the first time.
Editing a file afterwards does not change an existing account, except for FTP,
which is updated on every start. To change a password on a running site:

- WordPress: in `/wp-admin`, menu *Users*, or
  `docker exec wordpress wp --allow-root user update <name> --user_pass=<new>`
- Database: change it with `ALTER USER` and write the same value in the secret
  file and in `wp-config.php`.

To start again with new passwords and an empty site, edit the files and run
`make fclean && make`.

## Checking that everything works

```sh
make ps
```

Every service must be listed as `Up`, and `mariadb` as `Up (healthy)`.

| Check | Command | Expected |
|---|---|---|
| Site answers over HTTPS | `curl -kI https://gserafio.42.fr` | `HTTP/1.1 200 OK` |
| Port 80 is not served by the stack | `docker ps --format '{{.Names}} {{.Ports}}'` | no `:80->` entry |
| TLS 1.1 is refused | `openssl s_client -connect gserafio.42.fr:443 -tls1_1` | handshake error |
| TLS 1.2 and 1.3 are accepted | same command with `-tls1_2` or `-tls1_3` | a certificate is shown |
| WordPress is installed | `docker exec wordpress wp --allow-root core is-installed && echo ok` | `ok` |
| Both users exist | `docker exec wordpress wp --allow-root user list` | two lines |
| Cache is connected | `docker exec wordpress wp --allow-root redis status` | `Status: Connected` |

If a service is not `Up`, read its messages:

```sh
make logs
docker logs wordpress
```
