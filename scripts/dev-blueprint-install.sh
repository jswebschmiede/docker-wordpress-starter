#!/usr/bin/env bash
# Clone the optional dev blueprint beside wordpress/ and drop its nested git
# history so the result can live in this repository as one monorepo.
set -euo pipefail

# Sets WP_CONTENT_PATH when the key is missing or empty.
# A non-empty value is left unchanged.
seed_wp_content_path() {
	local file="$1"
	local path="$2"
	local tmp
	local found=0
	local nonempty=0
	local line
	local value

	tmp="$(mktemp)"
	while IFS= read -r line || [ -n "$line" ]; do
		if [ "$found" -eq 0 ] && [ "${line#WP_CONTENT_PATH=}" != "$line" ]; then
			found=1
			value="${line#WP_CONTENT_PATH=}"
			if [ -n "$value" ]; then
				nonempty=1
				printf '%s\n' "$line" >>"$tmp"
			else
				printf 'WP_CONTENT_PATH=%s\n' "$path" >>"$tmp"
			fi
		else
			printf '%s\n' "$line" >>"$tmp"
		fi
	done <"$file"

	if [ "$found" -eq 0 ]; then
		printf 'WP_CONTENT_PATH=%s\n' "$path" >>"$tmp"
	fi

	mv "$tmp" "$file"

	if [ "$nonempty" -eq 1 ]; then
		echo "WP_CONTENT_PATH already set in boilerplate-theme/.env. Leaving it unchanged."
	else
		echo "Set WP_CONTENT_PATH=${path}"
	fi
}

url="${WP_DEV_BLUEPRINT_URL:-}"
dir="${WP_DEV_BLUEPRINT_DIR:-dev-blueprint}"
dir="${dir%/}"

if [ -z "$url" ]; then
	echo "WP_DEV_BLUEPRINT_URL is empty. Skipping dev blueprint install."
	exit 0
fi

if [ -z "$dir" ]; then
	echo "Error: WP_DEV_BLUEPRINT_DIR must not be empty." >&2
	exit 1
fi

case "$dir" in
	/*|..|../*|*/..|*/../*|*..*)
		echo "Error: WP_DEV_BLUEPRINT_DIR must be a relative path inside this project." >&2
		exit 1
		;;
esac

root="$(cd "$(dirname "$0")/.." && pwd)"
dest="${root}/${dir}"
wp_content_path="${root}/wordpress/wp-content"

if [ -e "$dest" ] && [ ! -d "$dest" ]; then
	echo "Error: ${dir} exists and is not a directory." >&2
	exit 1
fi

if [ -d "$dest" ] && [ -n "$(ls -A "$dest")" ]; then
	echo "Dev blueprint already present at ${dir}/. Skipping clone."
	exit 0
fi

mkdir -p "$(dirname "$dest")"
echo "Cloning dev blueprint into ${dir}/..."
git clone --depth 1 "$url" "$dest"
rm -rf "${dest}/.git"
echo "Removed nested git history from ${dir}/."

theme_env_example="${dest}/boilerplate-theme/.env.example"
theme_env="${dest}/boilerplate-theme/.env"

if [ ! -f "$theme_env_example" ]; then
	echo "No boilerplate-theme/.env.example found. Clone finished without seeding WP_CONTENT_PATH."
	exit 0
fi

if [ ! -f "$theme_env" ]; then
	cp "$theme_env_example" "$theme_env"
	echo "Created boilerplate-theme/.env from .env.example."
fi

seed_wp_content_path "$theme_env" "$wp_content_path"
