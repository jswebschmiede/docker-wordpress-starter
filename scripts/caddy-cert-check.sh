#!/usr/bin/env bash
# Restarts Caddy when it serves an expired leaf certificate.
#
# After a long downtime, Caddy's storage cleanup deletes leaf certificates that
# expired beyond the grace period while renewal still tries to read them. Caddy
# then keeps serving the expired certificate from memory. A restart reissues it.
set -euo pipefail

host=127.0.0.1
port="${WEB_PORT:-6969}"

served_cert_state() {
	local cert
	cert=$(openssl s_client -connect "$host:$port" -servername "$host" </dev/null 2>/dev/null | openssl x509 2>/dev/null) || true

	if [ -z "$cert" ]; then
		echo missing
	elif printf '%s\n' "$cert" | openssl x509 -noout -checkend 0 >/dev/null; then
		echo valid
	else
		echo expired
	fi
}

wait_for_state() {
	local wanted=$1 seconds=$2 state=missing

	for _ in $(seq 1 "$seconds"); do
		state=$(served_cert_state)
		case "$wanted" in
			any) [ "$state" != missing ] && break ;;
			*) [ "$state" = "$wanted" ] && break ;;
		esac
		sleep 1
	done

	echo "$state"
}

if ! command -v openssl >/dev/null 2>&1; then
	echo "openssl not found, skipping served certificate check."
	exit 0
fi

case "$(wait_for_state any 15)" in
	valid)
		echo "Served certificate is valid."
		exit 0
		;;
	missing)
		echo "Could not read the certificate from https://$host:$port, skipping check." >&2
		exit 0
		;;
esac

echo "Served certificate has expired. Restarting Caddy to issue a new one..."
env UID="$(id -u)" GID="$(id -g)" docker compose restart caddy

if [ "$(wait_for_state valid 30)" = valid ]; then
	echo "Caddy issued a new certificate. Reload the browser tab."
else
	echo "Caddy still serves no valid certificate. Run 'make cert-reset' for a full reset." >&2
	exit 1
fi
