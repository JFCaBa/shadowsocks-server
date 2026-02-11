FROM ubuntu:20.04

LABEL maintainer="Shadowsocks Docker Container"

# Prevent dialog prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
        python3 \
        python3-pip \
        wget \
        curl \
        ca-certificates \
        gnupg \
        unzip \
        && rm -rf /var/lib/apt/lists/*

# Install shadowsocks-libev which has better support for modern encryption methods
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        shadowsocks-libev \
        libsodium23 \
        libssl1.1 \
        libev4 \
        libudns0 && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/shadowsocks /opt/shadowsocks

# Download and install v2ray-plugin
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        V2RAY_ARCH="linux-amd64"; \
        V2RAY_NAME="v2ray-plugin_linux_amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        V2RAY_ARCH="linux-arm64"; \
        V2RAY_NAME="v2ray-plugin_linux_arm64"; \
    else \
        V2RAY_ARCH="linux-amd64"; \
        V2RAY_NAME="v2ray-plugin_linux_amd64"; \
    fi && \
    wget -O /tmp/v2ray-plugin.tar.gz $(curl -s https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest | grep browser_download_url | grep "$V2RAY_ARCH" | cut -d '"' -f 4) && \
    tar -xzf /tmp/v2ray-plugin.tar.gz -C /tmp/ && \
    mv /tmp/$V2RAY_NAME /usr/local/bin/v2ray-plugin && \
    chmod +x /usr/local/bin/v2ray-plugin && \
    rm /tmp/v2ray-plugin.tar.gz

# Copy configuration templates
COPY ./config.json /etc/shadowsocks/config.json.template
COPY ./start.sh /opt/shadowsocks/start.sh

# Make startup script executable
RUN chmod +x /opt/shadowsocks/start.sh

# Expose the port Shadowsocks will run on
EXPOSE 8389

# Set the startup command
CMD ["/opt/shadowsocks/start.sh"]