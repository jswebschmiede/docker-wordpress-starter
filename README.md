# WordPress Development Environment with Docker

This project provides a Docker-based development environment for WordPress. It allows for quick and easy setup of a WordPress instance with all necessary services. On Windows use it with WSL2.

## Features

- WordPress CMS (official image, Apache variant)
- MySQL Database
- phpMyAdmin for database management
- MailHog for email testing
- Optional plugin/theme management via Make targets (clone from Git, reset folders)

## Prerequisites

- Docker
- Docker Compose
- Make (optional, but recommended). If not installed on Debian/Ubuntu use `sudo apt-get update && sudo apt-get install make`.

## Quick Start

1. Clone this repository:

```
git clone <your-repo-url>
cd docker-wordpress
```

2. Copy the `.env.example` file to `.env` and adjust the values as needed:

```
cp .env.example .env
```

3. Start the environment:

```
make up
```

4. Open your browser and navigate to:

- WordPress Frontend: http://localhost:6969
- WordPress Backend: http://localhost:6969/wp-admin
- phpMyAdmin: http://localhost:8080
- MailHog: http://localhost:8025

## Makefile Commands

- `make up`: Starts the containers
- `make start`: Displays information about the running environment
- `make stop`: Stops the containers
- `make down`: Stops and removes the containers
- `make reset`: Removes all containers and local data
- `make log`: Shows the logs of the containers
- `make config`: Shows the resolved docker compose configuration

### Optional content helpers

- `make plugins-reset`: Clears `wordpress/wp-content/plugins` (keeps `index.php` if present)
- `make themes-reset`: Clears `wordpress/wp-content/themes` (keeps `index.php` and the slugs in `THEMES_KEEP`)
- `make plugins-install`: Clones or updates repositories from `PLUGINS_GIT_URLS` into `wp-content/plugins`
- `make themes-install`: Clones or updates repositories from `THEMES_GIT_URLS` into `wp-content/themes`
- `make content-install`: Runs `plugins-install` and `themes-install`
- `make content-reset`: Runs `plugins-reset` and `themes-reset`

## Project Structure

- `docker-compose.yml`: Defines the Docker services
- `.env`: Contains environment variables for configuration
- `makefile`: Contains useful commands for project management
- `wordpress/`: Directory for WordPress files (created on first start)
- `db/`: Directory for database files (created on first start)
- `docker/php/conf.d/uploads.ini`: PHP upload limits configuration

## Customization

You can customize the configuration in the `.env` file to change ports, versions, and other settings.

## Troubleshooting

If you encounter problems, try the following steps:

1. Stop the containers with `make down`
2. Remove local data with `make reset`
3. Restart the environment with `make up`

If problems persist, check the logs with `make log`.

## Contributing

Contributions are welcome! Please create an issue or pull request for improvement suggestions.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
