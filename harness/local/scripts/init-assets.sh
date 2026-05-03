#!/usr/bin/env bash
set -euo pipefail

# Generates local-only Pulp config assets under .work/. The generated key and
# password are for the disposable local harness only.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "${SCRIPT_DIR}/common.sh"

mkdir -p \
  "${HARNESS_WORKDIR}/assets/bin" \
  "${HARNESS_WORKDIR}/assets/certs" \
  "${HARNESS_WORKDIR}/assets/nginx"

cat > "${HARNESS_WORKDIR}/assets/settings.py" <<PY
SECRET_KEY = "local-harness-only"
CONTENT_ORIGIN = "http://localhost:${PULP_HTTP_PORT:-18080}"
DATABASES = {"default": {"HOST": "postgres", "ENGINE": "django.db.backends.postgresql", "NAME": "pulp", "USER": "pulp", "PASSWORD": "password", "PORT": "5432", "CONN_MAX_AGE": 0, "OPTIONS": {"sslmode": "prefer"}}}
CACHE_ENABLED = True
REDIS_HOST = "redis"
REDIS_PORT = 6379
REDIS_PASSWORD = ""
ALLOWED_IMPORT_PATHS = ["/var/lib/pulp/imports"]
ALLOWED_EXPORT_PATHS = ["/var/lib/pulp/exports"]
ANALYTICS = False
STATIC_ROOT = "/var/lib/operator/static/"
PY

python3 - <<'PY' > "${HARNESS_WORKDIR}/assets/certs/database_fields.symmetric.key"
import base64
import os
print(base64.urlsafe_b64encode(os.urandom(32)).decode())
PY

cat > "${HARNESS_WORKDIR}/assets/bin/nginx.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
if [ "${container:-}" = "podman" ]; then
  export NAMESERVER="$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf)"
else
  export NAMESERVER="$(awk '/nameserver/ {print $2}' /etc/resolv.conf | tr '\n' ' ')"
fi
envsubst '$NAMESERVER' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
for file in /etc/nginx/pulp/*.conf ; do
  sed -i 's/pulp-api/$pulp_api:24817/' "$file"
  sed -i 's/pulp-content/$pulp_content:24816/' "$file"
done
exec nginx -g "daemon off;"
EOF
chmod +x "${HARNESS_WORKDIR}/assets/bin/nginx.sh"

cat > "${HARNESS_WORKDIR}/assets/nginx/nginx.conf.template" <<'EOF'
error_log /dev/stdout info;
worker_processes 1;
events { worker_connections 1024; accept_mutex off; }
http {
    access_log /dev/stdout;
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    types_hash_max_size 4096;
    server {
        resolver $NAMESERVER valid=10s;
        set $pulp_api pulp_api;
        set $pulp_content pulp_content;
        listen 8080 default_server;
        listen [::]:8080 default_server;
        server_name $hostname;
        client_max_body_size 10m;
        keepalive_timeout 5;
        root /opt/app-root/src;
        location /pulp/content/ {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_pass http://$pulp_content:24816;
        }
        location /pulp/api/v3/ {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_pass http://$pulp_api:24817;
        }
        include /etc/nginx/pulp/*.conf;
        location / {
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $http_host;
            proxy_redirect off;
            proxy_pass http://$pulp_api:24817;
        }
    }
}
EOF

echo "Generated local harness assets at ${HARNESS_WORKDIR}/assets"
