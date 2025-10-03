# LEAN Trading Bot Stack - Universal Tunnel Service
# Supports multiple tunneling services

FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    ssh \
    nodejs \
    npm \
    python3 \
    python3-pip \
    ca-certificates \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install tunneling tools

# Ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz && \
    tar -xzf ngrok-v3-stable-linux-amd64.tgz && \
    mv ngrok /usr/local/bin/ && \
    rm ngrok-v3-stable-linux-amd64.tgz

# LocalTunnel
RUN npm install -g localtunnel

# Cloudflare Tunnel
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared-linux-amd64.deb && \
    rm cloudflared-linux-amd64.deb

# PageKite
RUN pip3 install pagekite

# Telebit
RUN curl https://get.telebit.io/ | bash || true

# Create directories
RUN mkdir -p /config /logs /scripts

# Copy tunnel scripts
COPY scripts/ /scripts/
COPY config/ /config/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make scripts executable
RUN chmod +x /scripts/*.sh

# Create non-root user
RUN useradd -r -s /bin/bash tunnel
RUN chown -R tunnel:tunnel /config /logs /scripts

# Switch to non-root user
USER tunnel

# Working directory
WORKDIR /config

# Start supervisor (which will start appropriate tunnel service)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]