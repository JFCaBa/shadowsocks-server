# Dockerized Shadowsocks + v2ray-plugin

A complete solution for deploying Shadowsocks server with v2ray-plugin WebSocket transport in a Docker container. Based on `shadowsocks-libev` and optimized for production environments.

## Overview

This container runs `shadowsocks-libev` (the C version) with `v2ray-plugin` for WebSocket transport over TLS. The setup is designed to work alongside a host-based Nginx server for SSL termination.

## Features

- Based on `shadowsocks-libev` (same as production systems)
- Supports AES-256-GCM and other modern encryption methods
- v2ray-plugin with WebSocket transport and mux=0 support
- Configurable via environment variables
- Optimized for Nginx SSL termination setups
- Production-ready and tested

## Environment Variables

- `SHADOWSOCKS_PASSWORD` - Password for the Shadowsocks server (required)
- `SHADOWSOCKS_HOST` - Host for the WebSocket connection (default: skiprestriction.uk)
- `SHADOWSOCKS_PATH` - WebSocket path (default: /shadowsocks)
- `SHADOWSOCKS_METHOD` - Encryption method (default: aes-256-gcm)
- `SHADOWSOCKS_SERVER_PORT` - Server port (default: 8389)

## Quick Start

### Using the Public Image

```bash
docker run -d \
  --name shadowsocks-server \
  --restart unless-stopped \
  -p 8389:8389 \
  -e SHADOWSOCKS_PASSWORD=your_secure_password \
  -e SHADOWSOCKS_HOST=your_domain.com \
  -e SHADOWSOCKS_METHOD=aes-256-gcm \
  jfca68/shadowsocks-server:latest
```

### Building Locally (Development)

```bash
# Clone and build the image
git clone <repository-url>
cd shadowsocks-docker
docker build -t jfca68/shadowsocks-server:latest .

# Run the container
docker run -d \
  --name shadowsocks-server \
  --restart unless-stopped \
  -p 8389:8389 \
  -e SHADOWSOCKS_PASSWORD=your_secure_password \
  -e SHADOWSOCKS_HOST=your_domain.com \
  -e SHADOWSOCKS_METHOD=aes-256-gcm \
  jfca68/shadowsocks-server:latest
```

## Complete Deployment Guide

### On Your Target VPS:

1. **Pull the Docker image**:
```bash
docker pull jfca68/shadowsocks-server:latest
```

2. **Run the container**:
```bash
docker run -d \
  --name shadowsocks-server \
  --restart unless-stopped \
  -p 8389:8389 \
  -e SHADOWSOCKS_PASSWORD=your_secure_password \
  -e SHADOWSOCKS_HOST=your_domain.com \
  -e SHADOWSOCKS_METHOD=aes-256-gcm \
  jfca68/shadowsocks-server:latest
```

3. **Verify the container is running**:
```bash
docker ps
docker logs shadowsocks-server
```

### Configure Nginx on the Host:

Create `/etc/nginx/conf.d/your_domain.conf` with:

```
# Nginx configuration for proxying WebSocket connections to shadowsocks container

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your_domain.com www.your_domain.com;

    # SSL certificate paths - adjust according to your certificate location
    ssl_certificate /etc/letsencrypt/live/your_domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your_domain.com/privkey.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;

    # For Let's Encrypt ACME challenges
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri $uri/ =404;
    }

    # WebSocket proxy for Shadowsocks container
    location /shadowsocks {
        proxy_pass http://127.0.0.1:8389;  # Points to your container
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300;

        # Hide nginx version from error pages
        proxy_hide_header X-Powered-By;
        proxy_hide_header Server;
    }

    # Optional: Return 404 for root requests
    location / {
        return 404;
    }
}

# HTTP server to redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name your_domain.com www.your_domain.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        try_files $uri $uri/ =404;
    }

    # Redirect all other HTTP traffic to HTTPS
    return 301 https://$server_name$request_uri;
}
```

4. **Test and reload Nginx**:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

5. **Obtain SSL certificates with Certbot**:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your_domain.com
```

## Client Configuration

### Shadowrocket (iOS):
- Server: your_domain.com
- Port: 443
- Password: your_secure_password
- Method: aes-256-gcm
- Plugin: v2ray-plugin
- Plugin Options: tls;path=/shadowsocks;host=your_domain.com;mux=0

## Managing the Container

- View logs: `docker logs shadowsocks-server`
- Follow logs: `docker logs -f shadowsocks-server`
- Restart: `docker restart shadowsocks-server`
- Stop: `docker stop shadowsocks-server`
- Remove: `docker rm shadowsocks-server`

## Docker Hub Repository

Image: `jfca68/shadowsocks-server:latest`
Repository: `https://hub.docker.com/r/jfca68/shadowsocks-server`

## Security Notes

- Use strong passwords with mixed characters
- Keep SSL certificates updated
- Regularly update the container image
- Monitor logs for suspicious activity

## Development Notes

- The container uses shadowsocks-libev (C version) for better performance and compatibility
- v2ray-plugin is integrated for WebSocket transport over TLS
- Configuration is processed via environment variables at runtime
- The image supports architecture detection (AMD64/ARM64)