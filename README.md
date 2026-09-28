# WordPress Development Environment with Docker

This project provides a Docker-based development environment for WordPress. It allows for quick and easy setup of a WordPress instance with all necessary services. On Windows use it with WSL2.

## Features

- WordPress CMS (official PHP-FPM image) behind Nginx, with Caddy terminating HTTPS
- MySQL Database
- phpMyAdmin for database management
- Mailpit for email testing
- WP-CLI for command-line management
- Optional plugin/theme management via Make targets (clone from Git, reset folders)

## Prerequisites

- Docker
- Docker Compose
- Make (optional, but recommended). If not installed on Debian/Ubuntu use `sudo apt-get update && sudo apt-get install make`.

## Quick Start

```bash
git clone https://github.com/jswebschmiede/docker-wordpress-starter.git <your-project-name>
cd <your-project-name>

cp .env.example .env
# Edit .env: set passwords, WP_ADMIN_*, WP_URL (must match https://127.0.0.1:${WEB_PORT})

make wp-fresh-start
```

`make wp-fresh-start` starts the stack, installs WordPress with admin user from `.env`, resets plugins/themes, and reinstalls from `PLUGINS_GIT_URLS` / `THEMES_GIT_URLS`. Optional `.env` options: `WP_LANG` (e.g. `de_DE` for German), `PLUGINS_SLUGS` (space-separated plugin slugs from wordpress.org, installed and activated), `THEMES_KEEP` (first theme is auto-activated). Open https://127.0.0.1:6969/wp-admin and log in with `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD`.

Port `6969` serves HTTPS. A request to `http://127.0.0.1:6969` is redirected to `https://127.0.0.1:6969`. `https://localhost:6969` works as well.

- `make up` – Start containers only. Fast, no WP setup. Also imports the local Caddy CA into the Windows user trust store when `powershell.exe` is available (WSL2). Containers do not start with the Docker daemon; start them with `make up`.
- `make install-wp` – Install WordPress manually (e.g. after `make reset`). If WordPress is already installed, updates `home` and `siteurl` to `WP_URL`.
- `make trust-cert` – Export the Caddy root CA and trust it. Runs automatically at the end of `make up`.
- `make wp-fresh-start` – Full setup: up + install-wp + content-reset + content-install. Use for first run or when you need a clean content state.

## WP-CLI Usage

```bash
make wp -- user list
make wp -- plugin list
make wp -- theme list
```

## Makefile Commands

### Core

- `make up`: Starts the containers and trusts the local Caddy CA
- `make trust-cert`: Exports `docker/caddy/pki/root.crt` and installs it into the Windows current-user root store when `powershell.exe` is available
- `make start`: Displays information about the running environment
- `make stop`: Stops the containers
- `make down`: Stops and removes the containers
- `make reset`: Removes all containers and local data
- `make log`: Shows the logs of the containers
- `make config`: Shows the resolved docker compose configuration

### Content helpers

- `make plugins-reset`: Clears `wordpress/wp-content/plugins` (keeps `index.php` if present)
- `make themes-reset`: Clears `wordpress/wp-content/themes` (keeps `index.php` and the slugs in `THEMES_KEEP`)
- `make activate-theme`: Activates the first theme from `THEMES_KEEP` (runs automatically at end of `wp-fresh-start`)
- `make install-plugins-slugs`: Installs and activates plugins from `PLUGINS_SLUGS` via wordpress.org (runs after content-install in `wp-fresh-start`)
- `make plugins-install`: Clones or updates repositories from `PLUGINS_GIT_URLS` into `wp-content/plugins`
- `make themes-install`: Clones or updates repositories from `THEMES_GIT_URLS` into `wp-content/themes`
- `make content-install`: Runs `plugins-install` and `themes-install`
- `make content-reset`: Runs `plugins-reset` and `themes-reset`

## Structure

- `docker-compose.yml` – Caddy (HTTPS), Nginx, WordPress (PHP-FPM), MySQL, phpMyAdmin, Mailpit, WP-CLI service
- `.env.example` – Template with `WP_ADMIN_*`, `WP_LANG`, `PLUGINS_SLUGS`, `THEMES_KEEP` for `make install-wp`
- `makefile` – `install-wp` (runs wp core install), `wp` (pass-through for any WP-CLI command)
- `wordpress/` – WordPress files (created on first start)
- `db/` – Database files (created on first start)
- `docker/php/conf.d/uploads.ini` – PHP upload limits configuration
- `docker/nginx/default.conf` – Nginx site config (permalinks, PHP-FPM, upload limit, HTTPS from `X-Forwarded-Proto`). `.htaccess` is ignored here; on an Apache host WordPress still uses `.htaccess` for permalinks.
- `docker/caddy/Caddyfile` – Local HTTPS reverse proxy in front of Nginx
- No Dockerfile – uses official `wordpress`, `wordpress:cli`, `nginx`, and `caddy` images

## URLs (default ports)

- WordPress Frontend: https://127.0.0.1:6969
- WordPress Backend: https://127.0.0.1:6969/wp-admin
- phpMyAdmin: http://127.0.0.1:8080
- Mailpit: http://127.0.0.1:8025

## Customization

You can customize the configuration in the `.env` file to change ports, versions, and other settings. Ensure `WP_URL` matches your actual URL (e.g. `https://127.0.0.1:6969` when using default `WEB_PORT`). After changing `WP_URL` on an existing install, run `make install-wp` so `home` and `siteurl` follow it.

- `WP_LANG`: Locale code for WordPress core (e.g. `de_DE` for German, `en_US` default). Installed and activated during `install-wp`.
- `PLUGINS_SLUGS`: Space-separated plugin slugs from wordpress.org (e.g. `akismet contact-form-7`). Plugins are installed and activated after `content-install` in `wp-fresh-start`.
- `THEMES_KEEP`: Space-separated theme slugs kept during `themes-reset`. The first slug is activated automatically after `content-install` in `wp-fresh-start`.

## Local HTTPS

Caddy issues certificates for `127.0.0.1` and `localhost` from its own CA. `make up` copies the root to `docker/caddy/pki/root.crt` and, on WSL2, adds it to the Windows current-user root store. Chrome and Edge trust that store. Restart the browser once if a certificate warning remains.

Firefox uses its own store. Import `docker/caddy/pki/root.crt` under Settings → Privacy & Security → Certificates → View Certificates → Authorities.

Without `powershell.exe`, `make trust-cert` only exports the file and prints how to install it into the Linux system store:

```bash
sudo cp docker/caddy/pki/root.crt /usr/local/share/ca-certificates/caddy-local-root.crt
sudo update-ca-certificates
```

## Troubleshooting

If you encounter problems, try the following steps:

1. Stop the containers with `make down`
2. Remove local data with `make reset`
3. Restart with `make wp-fresh-start` for a clean WordPress install, or `make up` if you only need the containers

If problems persist, check the logs with `make log`.

## Contributing

Contributions are welcome! Please create an issue or pull request for improvement suggestions.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
