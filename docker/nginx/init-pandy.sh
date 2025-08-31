#!/bin/sh
set -e

DOMAIN="pandy.pro"

echo "[nginx] 🚀 Inicializando configuração para $DOMAIN"

# Aguarda um pouco para certificados em caso de primeiro deploy
sleep 3

# Verifica se certificados SSL existem
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]; then
    echo "[nginx] ✅ Certificados SSL encontrados para $DOMAIN - Ativando HTTPS"
    cp /etc/nginx/conf.d/pandy-https.conf /etc/nginx/conf.d/default.conf
    echo "[nginx] 🔒 Modo HTTPS ativado"
else
    echo "[nginx] ⚠️ Certificados SSL não encontrados - Ativando HTTP"
    cp /etc/nginx/conf.d/pandy-http.conf /etc/nginx/conf.d/default.conf
    echo "[nginx] 🌐 Modo HTTP ativado"
fi

# Testa a configuração
echo "[nginx] 🔧 Testando configuração..."
nginx -t

# Verifica se deve executar em daemon mode
if [ "$1" = "--daemon-off" ]; then
    echo "[nginx] 🚀 Iniciando Nginx em modo daemon..."
    exec nginx -g 'daemon off;'
else
    echo "[nginx] ✅ Configuração aplicada com sucesso"
fi