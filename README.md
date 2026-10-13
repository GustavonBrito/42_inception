*This project has been created as part of the 42 curriculum by gserafio.*

# Inception

## Description

Inception is a system administration project: a small web infrastructure built
with Docker Compose, where every service runs in its own container and every
image is built from a Dockerfile written for this project. No ready-made image
is pulled, apart from the Alpine base.

The goal is to understand what a container really is by assembling the pieces
by hand: a web server, an application server and a database that only talk to
each other through a private network, with the data kept in volumes so it
survives the containers.

### What is in the stack

| Service | Role | Reachable from the host |
|---|---|---|
| `nginx` | TLS termination, the only entry point of the site | `443` |
| `wordpress` | WordPress running on php-fpm, no web server inside | no |
| `mariadb` | Database of the site | no |
| `redis` (bonus) | Object cache for WordPress | no |
| `vsftpd` (bonus) | FTP access to the WordPress files | `21`, `21100-21104` |
| `adminer` (bonus) | Web interface for the database | `8080` |
| `website` (bonus) | Static site (HTML, CSS and JavaScript) | `8081` |

```
                 host
   443 ──────────┐
                 ▼
              ┌───────┐  fastcgi :9000  ┌───────────┐  :3306  ┌─────────┐
              │ nginx │ ───────────────▶│ wordpress │────────▶│ mariadb │
              └───────┘                 └───────────┘         └─────────┘
                  │                       │       │                │
                  └── volume wordpress ───┘       └─▶ redis        └── volume mariadb
```

### Design choices

- **Base image.** Every Dockerfile starts from `alpine:3.23`, the penultimate
  stable release when the project was written. The tag is fixed, `latest` is
  never used, and the versions of WordPress, WP-CLI, Adminer and the cache
  plugin are fixed as build arguments.
- **Configuration at start, not at build.** The images hold only software.
  The database, `wp-config.php`, the WordPress installation and the TLS
  certificate are created by each container's entrypoint the first time it
  starts, so no password is ever stored in an image layer and the same image
  works for any domain.
- **One process per container, in the foreground.** Each entrypoint ends with
  `exec`, so the daemon becomes PID 1 and receives the stop signals. There is
  no `tail -f`, `sleep infinity` or shell loop keeping a container alive.
- **Start order.** `mariadb` has a healthcheck and `wordpress` waits for it
  with `depends_on: condition: service_healthy`. Every service uses
  `restart: always`.
- **Sources.** `srcs/docker-compose.yml` describes the stack and
  `srcs/requirements/<service>/` holds one directory per service with its
  `Dockerfile`, a `conf/` directory for configuration files and a `tools/`
  directory for scripts.

### Virtual machines vs Docker

A virtual machine emulates hardware and boots a complete operating system with
its own kernel; it is strongly isolated, but takes gigabytes of disk and tens
of seconds to start. A container is an ordinary process of the host, isolated
by kernel features (namespaces and cgroups) and sharing the host kernel; it
starts in milliseconds and its image contains only the program and its
libraries. This project uses containers because each service is a single
program, and it runs inside a virtual machine because the subject asks for an
environment where the student is free to administer Docker.

### Secrets vs environment variables

Environment variables are visible to anyone who can run `docker inspect` and
are inherited by every child process, so they are used here only for values
that are not sensitive: domain name, database name, user names. Passwords are
Docker secrets: files kept outside git in `secrets/`, mounted read-only at
`/run/secrets/<name>` only in the containers that need them, and read by the
entrypoint when it is required.

### Docker network vs host network

With `network: host` a container shares the network stack of the host: every
port it opens is open on the machine and there is no isolation between
services. This project uses a user-defined bridge network, `inception`.
Containers reach each other by service name through Docker's internal DNS
(`wordpress:9000`, `mariadb:3306`), and only the ports published explicitly
exist on the host. That is why the database cannot be reached from outside.

### Docker volumes vs bind mounts

A bind mount maps a host path directly into a container: simple, but tied to
the layout of that machine and not managed by Docker. A named volume is
created and listed by Docker (`docker volume ls`) and can be shared between
services by name. The subject requires named volumes whose data lives in
`/home/<login>/data`, so the two volumes of the project are named volumes of
the `local` driver configured to store their data in that directory:
`wordpress` for the site files and `mariadb` for the database.

## Instructions

### Requirements

- Linux with Docker Engine and the Docker Compose plugin
- `make`
- The user must be allowed to run `docker` (member of the `docker` group)

### 1. Point the domain to the machine

```sh
sudo sh -c 'echo "127.0.0.1 gserafio.42.fr" >> /etc/hosts'
```

### 2. Build and start

```sh
git clone https://github.com/GustavonBrito/42_inception.git
cd 42_inception
make
```

The first `make` creates what is not stored in git:

- `srcs/.env`, copied from `srcs/.env.example`;
- `secrets/*.txt`, one random password per file;
- the data directories `/home/<user>/data/wordpress` and `/home/<user>/data/mariadb`.

To choose your own values, create `srcs/.env` and the files in `secrets/`
before running `make`: existing files are never overwritten.

### 3. Open the site

- Site: <https://gserafio.42.fr>
- Administration: <https://gserafio.42.fr/wp-admin>

The certificate is self-signed, so the browser asks for confirmation the first
time.

### Make targets

| Target | Effect |
|---|---|
| `make` | create missing configuration, build the images, start everything |
| `make up` | start without rebuilding |
| `make down` | stop and remove the containers and the network; data is kept |
| `make stop` / `make start` | pause and resume the containers |
| `make ps` / `make logs` | state and last log lines of the services |
| `make re` | `down` followed by `make` |
| `make clean` | `down` and remove the images of this project |
| `make fclean` | `clean`, remove the volumes and **delete the site and database data** |

More detail is in [USER_DOC.md](USER_DOC.md) for people using the stack and in
[DEV_DOC.md](DEV_DOC.md) for people changing it.

## Resources

### References

- [Docker documentation](https://docs.docker.com/): Dockerfile reference,
  Compose file reference, networking, volumes and secrets
- [Dockerfile best practices](https://docs.docker.com/build/building/best-practices/)
- [NGINX documentation](https://nginx.org/en/docs/), in particular
  `ngx_http_ssl_module` and `ngx_http_fastcgi_module`
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/), `mariadb-install-db`
  and account management
- [WordPress developer handbook](https://developer.wordpress.org/advanced-administration/)
  and [WP-CLI commands](https://developer.wordpress.org/cli/commands/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Alpine Linux packages](https://pkgs.alpinelinux.org/packages) and
  [release branches](https://alpinelinux.org/releases/)
- [vsftpd.conf manual](https://security.appspot.com/vsftpd/vsftpd_conf.html)
- [Redis Object Cache plugin](https://wordpress.org/plugins/redis-cache/)

### Use of AI

An AI assistant was used in three parts of the project:

- checking the repository against the evaluation checklist to find what did
  not comply;
- reworking the Dockerfiles, the entrypoint scripts and the Compose file so
  that configuration and passwords are handled when the containers start;
- drafting this README and the two documentation files.

Every suggestion was run and checked on a live stack before being kept.
