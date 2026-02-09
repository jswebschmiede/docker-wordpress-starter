include .env

# Validate required environment variables
validate:
	@if [ -z "$(MYSQL_ROOT_PASSWORD)" ]; then echo "Error: MYSQL_ROOT_PASSWORD is required in .env file"; exit 1; fi
	@if [ -z "$(WEB_PORT)" ]; then echo "Error: WEB_PORT is required in .env file"; exit 1; fi
	@if [ -z "$(PROJECT_NAME)" ]; then echo "Error: PROJECT_NAME is required in .env file"; exit 1; fi

config:
	@UID=$$(id -u) GID=$$(id -g) docker compose config

down: stop
	-@UID=$$(id -u) GID=$$(id -g) docker compose down

log:
	-@UID=$$(id -u) GID=$$(id -g) docker compose logs

reset: down
	-@rm -rf db wordpress

start: validate
	@clear
	@printf "\033[1;33m%s\033[0m\n\n" "To start your site, please jump to http://127.0.0.1:${WEB_PORT}"
	@printf "\033[1;33m%s\033[0m\n\n" "Go to http://127.0.0.1:${WEB_PORT}/wp-admin to open your backend."
	@printf "\033[1;33m%s\033[0m\n\n" "Go to http://127.0.0.1:8080 to open phpMyAdmin."
	@printf "\033[1;33m%s\033[0m\n\n" "Go to http://127.0.0.1:8025 to open MailHog."

	@printf "\033[1;104m%s\033[0m\n\n" "Below a summary of your current installation:"

	@printf "\033[1;34m%s\033[0m\n\n" "WORDPRESS"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Project name" "${PROJECT_NAME}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${WORDPRESS_VERSION}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n\n" " * Port" "${WEB_PORT}"

	@printf "\033[1;34m%s\033[0m\n\n" "DATABASE"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Host" "wordpressdb"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * User name" "${DB_USER}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Password" "${DB_PASSWORD}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Database name" "${DB_NAME}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${MYSQL_VERSION}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n\n" " * Port" "${MYSQL_PORT}"

	@printf "\033[1;34m%s\033[0m\n\n" "PHPMYADMIN"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${PHPMYADMIN_VERSION}"

	@printf "\033[1;34m%s\033[0m\n\n" "MAILHOG"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${MAILHOG_VERSION}"

stop:
	-@UID=$$(id -u) GID=$$(id -g) docker compose stop

up: validate
	-@mkdir -p db wordpress
	@UID=$$(id -u) GID=$$(id -g) docker compose up --detach
