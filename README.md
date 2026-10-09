# 42_inception

Infraestrutura com Docker Compose: **NGINX (TLS) + WordPress (php-fpm) + MariaDB**, mais os bônus **Redis, vsftpd (FTP), Adminer e um site estático**. Todas as imagens são construídas a partir de `alpine:3.16`.

---

## 1. Pré-requisitos (num computador novo)

| O quê | Por quê |
|---|---|
| Docker Engine + plugin `docker compose` (v2) | O Makefile usa `docker compose` (com espaço), não `docker-compose` |
| `make`, `bash`, `sudo` | O Makefile chama `bash` e `sudo rm` nos alvos de limpeza |
| Usuário no grupo `docker` | Para rodar `docker` sem sudo: `sudo usermod -aG docker $USER` e depois **fazer logout/login** |
| Internet no build | Os Dockerfiles baixam pacotes `apk`, o WordPress (`wordpress.org/latest.zip`) e o Adminer (GitHub) |
| Portas livres: **443, 80, 3306, 6379, 21, 8080** | Se a máquina tiver apache/nginx/mysql/redis locais rodando, pare-os antes (`sudo systemctl stop apache2 mysql ...`) |

```bash
# Ubuntu/Debian
sudo apt install make docker.io docker-compose-v2   # ou instale o Docker pelo site oficial
sudo usermod -aG docker $USER                       # depois logout/login
```

---

## 2. Passo a passo para rodar

```bash
git clone https://github.com/Projetos-Pessoais-gbrito/42_inception.git
cd 42_inception
```

### 2.1 Conferir o `srcs/.env`
O arquivo **`srcs/.env` é obrigatório** (o compose lê as variáveis dele). Ele está versionado no repo, mesmo estando no `.gitignore` (foi adicionado antes do ignore). Conteúdo esperado:

```env
DB_NAME=wordpress
DB_ROOT=rootpass
DB_USER=wpuser
DB_PASS=wppass
FTP_USR=ftpuser
FTP_PWD=ftppass
```

> `DOMAIN_NAME`, `CERT_` e `KEY_` existem no `.env` mas **não são usados** por nada — o domínio e o certificado estão escritos direto no `nginx.conf`.

### 2.2 Apontar o domínio para a máquina local
O NGINX responde em **`gserafio.42.sp`**. Adicione no `/etc/hosts`:

```bash
echo "127.0.0.1 gserafio.42.sp" | sudo tee -a /etc/hosts
```

### 2.3 Subir

```bash
make build     # primeira vez: cria ~/data/{mariadb,wordpress} e faz build de tudo
# nas próximas vezes:
make           # sobe sem rebuildar
```

### 2.4 Acessar

| Serviço | URL / comando |
|---|---|
| WordPress (via NGINX, TLS) | https://gserafio.42.sp |
| Site estático (bônus) | http://localhost |
| Adminer (bônus) | http://localhost:8080 — servidor `mariadb`, usuário `wpuser`, senha `wppass`, base `wordpress` |
| FTP (bônus) | `ftp localhost 21` — usuário `ftpuser`, senha `ftppass` (cai em `/var/www`, os arquivos do WordPress) |
| Redis (bônus) | `docker exec -it redis redis-cli ping` → `PONG` |
| MariaDB | `docker exec -it mariadb mysql -u wpuser -pwppass wordpress` |

Na **primeira vez** o WordPress abre o assistente de instalação (`wp-admin/install.php`) — crie o site e o usuário admin por lá (não há wp-cli automatizando isso). Para o Redis ser usado de verdade pelo WordPress, instale e ative o plugin **Redis Object Cache** no painel (o `wp-config.php` já tem `WP_REDIS_HOST=redis`).

---

## 3. Comandos do Makefile

| Alvo | O que faz |
|---|---|
| `make` / `make all` | Cria `~/data` (se não existir) e `docker compose up -d` |
| `make build` | Igual, mas com `--build` |
| `make down` | Para e remove os containers |
| `make re` | `down` + `up -d --build` |
| `make clean` | `down` + `docker system prune -a` (**pede confirmação**) + `sudo rm -rf ~/data/wordpress/* ~/data/mariadb/*` |
| `make fclean` | Para **todos** os containers da máquina e apaga **todas** as imagens/volumes/redes Docker + os dados em `~/data` |

> ⚠️ `fclean` não é só deste projeto: ele derruba e apaga tudo de Docker na máquina.

---

## 4. Estrutura

```
42_inception/
├── Makefile
└── srcs/
    ├── .env                         # variáveis (DB, FTP)
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/      Dockerfile, conf/nginx.conf, tools/ (cert + key usados pelo nginx)
        ├── mariadb/    Dockerfile, conf/create_db.sh
        ├── wordpress/  Dockerfile, conf/wp-config-create.sh, tools/make_dir.sh
        ├── tools/      cópia do cert + key (não montada em nenhum container)
        └── bonus/      redis/, vsftpd/, adminer/, website/
```

Como as peças se conectam:

- **nginx** (porta 443, só TLSv1.2/1.3) → serve `/var/www` e manda os `.php` para `wordpress:9000` (php-fpm).
- **wordpress** → fala com `mariadb:3306` e com `redis:6379`.
- **nginx**, **wordpress** e **vsftpd** compartilham o volume `wp-volume` (= `~/data/wordpress`).
- **mariadb** guarda os dados em `db-volume` (= `~/data/mariadb`).
- Todos ficam na rede bridge `inception`, exceto o `website`, que é isolado.
- `nginx.conf` e o certificado são montados do host (`./requirements/nginx/conf` e `./requirements/nginx/tools`), então dá para editar sem rebuildar — basta `docker restart nginx`.

---

## 5. Pontos de atenção num computador diferente

1. **Volumes em `/home/$USER/data`** — o compose usa `${USER}` no caminho. Se você rodar com `sudo make`, `$USER` vira `root` e o caminho quebra. Rode como seu usuário normal.
2. **Dados antigos em `~/data`** — os scripts só criam o banco/`wp-config.php` se ainda não existirem. Se mudar senhas no `.env`, apague `~/data/mariadb/*` e `~/data/wordpress/*` (`make clean`) e faça `make build`, senão os dados velhos continuam valendo.
3. **`make_dir.sh` só cria as subpastas se `~/data` não existir.** Se `~/data` já existir sem `mariadb/` e `wordpress/`, crie na mão: `mkdir -p ~/data/mariadb ~/data/wordpress`.
4. **Certificado** — o `.crt`/`.key` foram gerados com **mkcert** nesta máquina (válidos até 07/2028). Em outro computador o navegador vai mostrar aviso de "não seguro" (é só aceitar). Para regenerar:
   ```bash
   # com mkcert (sem aviso no navegador)
   mkcert -install
   mkcert -cert-file srcs/requirements/nginx/tools/gserafio.42.sp.crt \
          -key-file  srcs/requirements/nginx/tools/gserafio.42.sp.key gserafio.42.sp
   # ou com openssl (autoassinado)
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout srcs/requirements/nginx/tools/gserafio.42.sp.key \
     -out    srcs/requirements/nginx/tools/gserafio.42.sp.crt -subj "/CN=gserafio.42.sp"
   ```
5. **Mudar o login/domínio** — está fixo como `gserafio.42.sp` em `nginx.conf` (`server_name` e caminhos do certificado) e nos nomes dos arquivos em `nginx/tools/`. Mude os três juntos + `/etc/hosts`.
6. **Senha do root do MariaDB** — o `mariadb/Dockerfile` não declara `ARG DB_ROOT`, então o `ALTER USER root` roda com senha vazia. Para entrar como root: `docker exec -it mariadb mysql -u root`. Se quiser corrigir, adicione `DB_ROOT` na linha `ARG` do Dockerfile.
7. **FTP em modo passivo** — só a porta 21 está publicada. Se um cliente FTP gráfico travar ao listar arquivos, use modo ativo ou teste por dentro do container.
8. **Alpine 3.16 está em fim de vida** — se algum dia o `apk` falhar ao baixar pacotes, troque o `FROM` para uma versão mais nova (atenção: os nomes `php8`/`php-fpm8` mudam em versões novas).
9. **Senhas no repo** — o `.env` e a chave privada estão commitados. São só valores de teste/locais; não reutilize em nada real.

---

## 6. Debug rápido

```bash
docker ps                          # todos os 7 containers devem estar "Up"
docker compose -f srcs/docker-compose.yml logs -f <servico>
docker exec -it <container> sh     # entrar no container
curl -vk https://gserafio.42.sp    # testar TLS / NGINX
```

- **502 Bad Gateway** → o `wordpress` (php-fpm) não está de pé: veja `docker logs wordpress`.
- **"Error establishing a database connection"** → `mariadb` caiu ou os dados em `~/data/mariadb` são de um `.env` antigo (ver item 5.2).
- **"port is already allocated"** → algum serviço do host está usando a porta (ver pré-requisitos).
