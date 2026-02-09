ARG NGINX_VERSION=${NGINX_VERSION:-1.25}

FROM nginx:${NGINX_VERSION}

# Nginx Konfiguration kopieren
COPY conf.d/default.conf /etc/nginx/conf.d/default.conf

# SSL-Verzeichnis erstellen
RUN mkdir -p /etc/nginx/ssl

# Erstelle das Verzeichnis und setze dann die Berechtigungen
RUN mkdir -p /var/www/html && \
    chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html
