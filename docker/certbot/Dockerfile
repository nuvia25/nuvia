FROM certbot/certbot:latest

# Install Cloudflare DNS plugin
RUN pip install --no-cache-dir certbot-dns-cloudflare==2.7.0 || pip install --no-cache-dir certbot-dns-cloudflare

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["certbot --version"]
