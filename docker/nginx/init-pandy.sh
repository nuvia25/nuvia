#!/bin/sh
set -eu

DOMAIN="pandy.pro"
CONF_DIR="/etc/nginx/conf.d"
HTTP_CONF="/etc/nginx/conf.d/pandy-http.conf"
HTTPS_CONF="/etc/nginx/conf.d/pandy-https.conf"
ACTIVE_CONF="/etc/nginx/conf.d/default.conf"

have_cert() {
  [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]
}

render_config() {
  if have_cert; then
    cp -f "$HTTPS_CONF" "$ACTIVE_CONF"
    echo "[init-pandy] Using HTTPS config for $DOMAIN"
  else
    cp -f "$HTTP_CONF" "$ACTIVE_CONF"
    echo "[init-pandy] Using HTTP config for $DOMAIN"
  fi
}

# Initial render
render_config

# If nginx isn't running yet, start it in background, then monitor cert changes
if ! pidof nginx >/dev/null 2>&1; then
  nginx -t || { echo "[init-pandy] nginx config test failed" >&2; exit 1; }
  # Start nginx in foreground if requested
  if [ "${1:-}" = "--daemon-off" ]; then
    exec nginx -g 'daemon off;'
  else
    nginx
  fi
fi

# If running as entrypoint, stay in a loop watching for cert appearance/changes
inotifywait_installed=0
if command -v inotifywait >/dev/null 2>&1; then
  inotifywait_installed=1
fi

if [ "$inotifywait_installed" -eq 1 ]; then
  # Efficient loop using inotify
  while true; do
    render_config
    nginx -t && nginx -s reload || echo "[init-pandy] reload failed"
    # Watch cert dir; fallback sleep if dir missing
    dir="/etc/letsencrypt/live/$DOMAIN"
    if [ -d "$dir" ]; then
      inotifywait -e create,modify,delete,move -q "$dir" >/dev/null 2>&1 || sleep 300
    else
      sleep 300
    fi
  done
else
  # Fallback: poll every 5 minutes
  while true; do
    render_config
    nginx -t && nginx -s reload || echo "[init-pandy] reload failed"
    sleep 300
  done
fi
