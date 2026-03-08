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
	-@sudo rm -rf db wordpress

plugins-reset:
	-@mkdir -p wordpress/wp-content/plugins
	-@find wordpress/wp-content/plugins -mindepth 1 -maxdepth 1 ! -name 'index.php' -exec rm -rf {} +

themes-reset:
	-@mkdir -p wordpress/wp-content/themes
	@set -e; \
	keep=" $(THEMES_KEEP) "; \
	for path in wordpress/wp-content/themes/*; do \
		[ -e "$$path" ] || continue; \
		name=$$(basename "$$path"); \
		if [ "$$name" = "index.php" ]; then \
			continue; \
		fi; \
		case "$$keep" in \
			*" $$name "*) echo "Keeping theme $$name" ;; \
			*) rm -rf "$$path" ;; \
		esac; \
	done

plugins-install:
	-@mkdir -p wordpress/wp-content/plugins
	@set -e; \
	for url in $(PLUGINS_GIT_URLS); do \
		clean_url=$$(printf '%s' "$$url" | sed -E 's#/*$$##'); \
		name=$${clean_url##*/}; \
		name=$${name##*:}; \
		name=$${name%.git}; \
		dest="wordpress/wp-content/plugins/$$name"; \
		if [ -d "$$dest/.git" ]; then \
			echo "Updating plugin $$name"; \
			git -C "$$dest" pull --ff-only; \
		else \
			echo "Cloning plugin $$name"; \
			git clone "$$clean_url" "$$dest"; \
		fi; \
	done

themes-install:
	-@mkdir -p wordpress/wp-content/themes
	@set -e; \
	for url in $(THEMES_GIT_URLS); do \
		clean_url=$$(printf '%s' "$$url" | sed -E 's#/*$$##'); \
		name=$${clean_url##*/}; \
		name=$${name##*:}; \
		name=$${name%.git}; \
		dest="wordpress/wp-content/themes/$$name"; \
		if [ -d "$$dest/.git" ]; then \
			echo "Updating theme $$name"; \
			git -C "$$dest" pull --ff-only; \
		else \
			echo "Cloning theme $$name"; \
			git clone "$$clean_url" "$$dest"; \
		fi; \
	done

content-install: plugins-install themes-install
content-reset: plugins-reset themes-reset

install-wp: validate
	@echo "Waiting for WordPress to be ready..."
	@sleep 5
	@if UID=$$(id -u) GID=$$(id -g) docker compose run --rm wpcli wp core is-installed --allow-root 2>/dev/null; then \
		echo "WordPress already installed."; \
	else \
		UID=$$(id -u) GID=$$(id -g) docker compose run --rm wpcli wp core install \
			--url="$(WP_URL)" \
			--title="$(PROJECT_NAME)" \
			--admin_user="$(WP_ADMIN_USER)" \
			--admin_password="$(WP_ADMIN_PASSWORD)" \
			--admin_email="$(WP_ADMIN_EMAIL)" \
			--skip-email \
			--allow-root; \
		echo "WordPress installed. Admin user: $(WP_ADMIN_USER)"; \
	fi
	@if [ -n "$(WP_LANG)" ]; then \
		echo "Installing and activating language $(WP_LANG)..."; \
		UID=$$(id -u) GID=$$(id -g) docker compose run --rm wpcli wp language core install $(WP_LANG) --activate --allow-root; \
	fi

install-plugins-slugs:
	@set -e; \
	for slug in $(PLUGINS_SLUGS); do \
		[ -n "$$slug" ] || continue; \
		echo "Installing and activating plugin $$slug..."; \
		UID=$$(id -u) GID=$$(id -g) docker compose run --rm wpcli wp plugin install $$slug --activate --allow-root; \
	done

activate-theme:
	@theme=$$(echo "$(THEMES_KEEP)" | awk '{print $$1}'); \
	if [ -n "$$theme" ]; then \
		echo "Activating theme $$theme..."; \
		UID=$$(id -u) GID=$$(id -g) docker compose run --rm wpcli wp theme activate $$theme --allow-root; \
	fi

wp:
	@UID=$$(id -u) GID=$$(id -g) docker compose run --rm wpcli wp $(filter-out $@,$(MAKECMDGOALS)) --allow-root

start: validate
	@clear
	@printf "\033[1;33m%s\033[0m\n\n" "To start your site, please jump to http://127.0.0.1:${WEB_PORT}"
	@printf "\033[1;33m%s\033[0m\n\n" "Go to http://127.0.0.1:${WEB_PORT}/wp-admin to open your backend."
	@printf "\033[1;33m%s\033[0m\n\n" "Go to http://127.0.0.1:8080 to open phpMyAdmin."
	@printf "\033[1;33m%s\033[0m\n\n" "Go to http://127.0.0.1:8025 to open Mailpit."
	@printf "\033[1;33m%s\033[0m\n\n" "First run or reset: use 'make wp-fresh-start' to install WordPress and content."
	@printf "\033[1;104m%s\033[0m\n\n" "Below a summary of your current installation:"
	@printf "\033[1;34m%s\033[0m\n\n" "WORDPRESS"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Project name" "${PROJECT_NAME}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${WORDPRESS_VERSION}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Port" "${WEB_PORT}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n\n" " * Fresh install" "make wp-fresh-start"
	@printf "\033[1;34m%s\033[0m\n\n" "DATABASE"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Host" "wordpressdb"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * User name" "${DB_USER}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Password" "${DB_PASSWORD}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Database name" "${DB_NAME}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${MYSQL_VERSION}"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n\n" " * Port" "${MYSQL_PORT}"
	@printf "\033[1;34m%s\033[0m\n\n" "PHPMYADMIN"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${PHPMYADMIN_VERSION}"
	@printf "\033[1;34m%s\033[0m\n\n" "MAILPIT"
	@printf "\033[1;34m%-30s\033[0m\033[1;104m%s\033[0m\n" " * Version" "${MAILPIT_VERSION}"

stop:
	-@UID=$$(id -u) GID=$$(id -g) docker compose stop

up: validate
	-@mkdir -p db wordpress
	@UID=$$(id -u) GID=$$(id -g) docker compose up --detach

wp-fresh-start: up
	@$(MAKE) install-wp
	@$(MAKE) content-reset
	@$(MAKE) content-install
	@$(MAKE) install-plugins-slugs
	@$(MAKE) activate-theme
	@echo "Fresh start complete. Content reset and reinstalled from PLUGINS_GIT_URLS / THEMES_GIT_URLS."

%:
	@:
