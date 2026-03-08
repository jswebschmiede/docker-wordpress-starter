# WordPress Development Environment with Docker

This project provides a Docker-based development environment for WordPress. It allows for quick and easy setup of a WordPress instance with all necessary services. On Windows use it with WSL2.

## Features

- WordPress CMS (official image, Apache variant)
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
# Edit .env: set passwords, WP_ADMIN_*, WP_URL (must match http://127.0.0.1:${WEB_PORT})

make wp-fresh-start
```

`make wp-fresh-start` starts the stack, installs WordPress with admin user from `.env`, resets plugins/themes, and reinstalls from `PLUGINS_GIT_URLS` / `THEMES_GIT_URLS`. Open http://127.0.0.1:6969/wp-admin and log in with `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD`.

- `make up` – Start containers only. Fast, no WP setup.
- `make install-wp` – Install WordPress manually (e.g. after `make reset`). Skips if already installed.
- `make wp-fresh-start` – Full setup: up + install-wp + content-reset + content-install. Use for first run or when you need a clean content state.

## WP-CLI Usage

```bash
make wp -- user list
make wp -- plugin list
make wp -- theme list
```

## Makefile Commands

### Core

- `make up`: Starts the containers
- `make start`: Displays information about the running environment
- `make stop`: Stops the containers
- `make down`: Stops and removes the containers
- `make reset`: Removes all containers and local data
- `make log`: Shows the logs of the containers
- `make config`: Shows the resolved docker compose configuration

### Content helpers

- `make plugins-reset`: Clears `wordpress/wp-content/plugins` (keeps `index.php` if present)
- `make themes-reset`: Clears `wordpress/wp-content/themes` (keeps `index.php` and the slugs in `THEMES_KEEP`)
- `make plugins-install`: Clones or updates repositories from `PLUGINS_GIT_URLS` into `wp-content/plugins`
- `make themes-install`: Clones or updates repositories from `THEMES_GIT_URLS` into `wp-content/themes`
- `make content-install`: Runs `plugins-install` and `themes-install`
- `make content-reset`: Runs `plugins-reset` and `themes-reset`

## Structure

- `docker-compose.yml` – WordPress, MySQL, phpMyAdmin, Mailpit, WP-CLI service
- `.env.example` – Template with `WP_ADMIN_*` variables for `make install-wp`
- `makefile` – `install-wp` (runs wp core install), `wp` (pass-through for any WP-CLI command)
- `wordpress/` – WordPress files (created on first start)
- `db/` – Database files (created on first start)
- `docker/php/conf.d/uploads.ini` – PHP upload limits configuration
- No Dockerfile – uses official `wordpress` and `wordpress:cli` images

## URLs (default ports)

- WordPress Frontend: http://127.0.0.1:6969
- WordPress Backend: http://127.0.0.1:6969/wp-admin
- phpMyAdmin: http://127.0.0.1:8080
- Mailpit: http://127.0.0.1:8025

## Customization

You can customize the configuration in the `.env` file to change ports, versions, and other settings. Ensure `WP_URL` matches your actual URL (e.g. `http://127.0.0.1:6969` when using default `WEB_PORT`).

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
