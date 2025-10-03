#!/bin/bash

# LEAN Trading Bot Stack - Installation Fix Script
# Naprawia problemy z brakującymi plikami i konfiguracją
# Author: AI Assistant for @szarastrefa
# Date: $(date +%Y-%m-%d)

set -e  # Exit on any error

echo "======================================"
echo "  LEAN Trading Bot Stack - NAPRAWA"
echo "======================================"
echo ""

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUKCES]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[OSTRZEŻENIE]${NC} $1"
}

log_error() {
    echo -e "${RED}[BŁĄD]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Ten skrypt musi być uruchomiony jako root"
    log_info "Uruchom: sudo $0"
    exit 1
fi

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "Katalog projektu: $PROJECT_DIR"
cd "$PROJECT_DIR" || exit 1

# Step 1: Create directory structure
log_info "Tworzenie struktury katalogów..."
mkdir -p docker/nginx
mkdir -p docker/web
mkdir -p docker/worker
mkdir -p docker/lean
mkdir -p docker/tunnel
mkdir -p scripts
mkdir -p data
mkdir -p logs
mkdir -p output
mkdir -p backups

log_success "Struktura katalogów utworzona"

# Step 2: Generate secure passwords if .env doesn't exist
if [ ! -f ".env" ] || [ ! -s ".env" ]; then
    log_info "Generowanie pliku .env z bezpiecznymi hasłami..."
    
    # Generate secure passwords
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    REDIS_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    FLASK_SECRET=$(openssl rand -hex 32)
    JWT_SECRET=$(openssl rand -hex 16)
    
    cat > .env << EOF
# LEAN Trading Bot Stack - Environment Configuration
# Generated: $(date)

# Database Configuration
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_USER=lean_user
POSTGRES_DB=lean_trading
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis Configuration
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_HOST=redis
REDIS_PORT=6379

# Flask Application
FLASK_SECRET_KEY=$FLASK_SECRET
FLASK_HOST=0.0.0.0
FLASK_PORT=5000

# QuantConnect API (Wypełnij swoimi danymi)
QC_API_ACCESS_TOKEN=your_quantconnect_token_here
QC_USER_ID=your_quantconnect_user_id

# Tunneling Services
NGROK_AUTH_TOKEN=
CLOUDFLARE_TUNNEL_TOKEN=

# LocalTunnel Configuration
TUNNEL_SERVICE=localtunnel
TUNNEL_SUBDOMAIN=eqtrader

# Application URLs
APP_URL=https://eqtrader.loca.lt
API_BASE_URL=http://localhost:5000

# LEAN Engine Configuration
LEAN_ENGINE_HOST=lean_engine
LEAN_ENGINE_PORT=8080
LEAN_DATA_FOLDER=/data
LEAN_OUTPUT_FOLDER=/output

# Security
JWT_SECRET_KEY=jwt_$JWT_SECRET
SESSION_TIMEOUT=3600

# Logging
LOG_LEVEL=INFO
LOG_FILE=/logs/trading.log

# Trading Configuration
DEFAULT_CASH=100000
DEFAULT_CURRENCY=USD
PAPER_TRADING=true

# Admin Credentials (Change after first login!)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123!@#

# Docker Configuration
DOCKER_COMPOSE_PROJECT_NAME=lean_trading_stack

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
EOF

    log_success "Plik .env utworzony z wygenerowanymi hasłami"
else
    log_warning "Plik .env już istnieje, pomijanie generowania"
fi

# Step 3: Fix docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    log_info "Naprawianie docker-compose.yml..."
    # Remove obsolete version line
    sed -i '/^version:/d' docker-compose.yml
    log_success "Usunięto przestarzałą linię 'version' z docker-compose.yml"
fi

# Step 4: Ensure nginx files exist
if [ ! -f "docker/nginx/Dockerfile" ]; then
    log_info "Tworzenie Dockerfile dla nginx..."
    cat > docker/nginx/Dockerfile << 'EOF'
FROM nginx:alpine

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Set proper permissions
RUN chmod 644 /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Create log directory
RUN mkdir -p /var/log/nginx

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOF
    log_success "Dockerfile dla nginx utworzony"
fi

if [ ! -f "docker/nginx/nginx.conf" ]; then
    log_info "Tworzenie konfiguracji nginx.conf..."
    cat > docker/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF
    log_success "Konfiguracja nginx.conf utworzona"
fi

if [ ! -f "docker/nginx/default.conf" ]; then
    log_info "Tworzenie default.conf dla nginx..."
    cat > docker/nginx/default.conf << 'EOF'
upstream webapp {
    server web:5000;
    keepalive 32;
}

server {
    listen 80;
    server_name localhost;
    client_max_body_size 100M;
    client_body_timeout 60s;
    client_header_timeout 60s;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Main proxy to Flask application
    location / {
        proxy_pass http://webapp;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Static files (if any)
    location /static/ {
        alias /app/static/;
        expires 1d;
        add_header Cache-Control "public, immutable";
    }

    # Favicon
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    # Robots.txt
    location = /robots.txt {
        log_not_found off;
        access_log off;
    }
}
EOF
    log_success "Konfiguracja default.conf utworzona"
fi

# Step 5: Create utility scripts
log_info "Tworzenie skryptów pomocniczych..."

# Script to show credentials and URLs
cat > scripts/show-info.sh << 'EOF'
#!/bin/bash

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

echo ""
echo "========================================"
echo "   LEAN Trading Bot - DANE DOSTĘPOWE"
echo "========================================"
echo ""
echo "🌐 DOSTĘP DO APLIKACJI:"
echo "   URL: ${APP_URL:-https://eqtrader.loca.lt}"
echo "   Dashboard: ${APP_URL:-https://eqtrader.loca.lt}/dashboard"
echo "   API: ${APP_URL:-https://eqtrader.loca.lt}/api"
echo ""
echo "🔐 DANE LOGOWANIA:"
echo "   Username: ${ADMIN_USERNAME:-admin}"
echo "   Password: ${ADMIN_PASSWORD:-admin123!@#}"
echo ""
echo "🗄️ BAZA DANYCH:"
echo "   Host: localhost:${POSTGRES_PORT:-5432}"
echo "   Database: ${POSTGRES_DB:-lean_trading}"
echo "   User: ${POSTGRES_USER:-lean_user}"
echo "   Password: ${POSTGRES_PASSWORD:-[sprawdź plik .env]}"
echo ""
echo "🔄 REDIS:"
echo "   Host: localhost:${REDIS_PORT:-6379}"
echo "   Password: ${REDIS_PASSWORD:-[sprawdź plik .env]}"
echo ""
echo "📊 QUANTCONNECT:"
if [ "${QC_API_ACCESS_TOKEN}" = "your_quantconnect_token_here" ]; then
    echo "   ⚠️  API Token: NIE SKONFIGUROWANY - ustaw w pliku .env"
else
    echo "   ✅ API Token: SKONFIGUROWANY"
fi
if [ "${QC_USER_ID}" = "your_quantconnect_user_id" ]; then
    echo "   ⚠️  User ID: NIE SKONFIGUROWANY - ustaw w pliku .env"
else
    echo "   ✅ User ID: SKONFIGUROWANY"
fi
echo ""
echo "⚠️  BEZPIECZEŃSTWO:"
echo "   - Zmień hasło administratora po pierwszym logowaniu"
echo "   - Uzupełnij dane QuantConnect w pliku .env"
echo "   - Regularnie aktualizuj hasła produkcyjne"
echo ""
echo "🛠️  POLECENIA:"
echo "   docker-compose up -d    # uruchom serwisy"
echo "   docker-compose logs -f  # zobacz logi"
echo "   docker-compose down     # zatrzymaj serwisy"
echo "========================================"
EOF

# Script to start tunnel
cat > scripts/start-tunnel.sh << 'EOF'
#!/bin/bash

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

SUBDOMAIN=${TUNNEL_SUBDOMAIN:-"eqtrader"}
PORT=${FLASK_PORT:-5000}

echo "Uruchamianie LocalTunnel..."
echo "Subdomena: $SUBDOMAIN"
echo "Port: $PORT"
echo "URL: https://$SUBDOMAIN.loca.lt"
echo ""

# Check if localtunnel is installed
if ! command -v lt &> /dev/null; then
    echo "LocalTunnel nie jest zainstalowany. Instalowanie..."
    if command -v npm &> /dev/null; then
        npm install -g localtunnel
    else
        echo "NPM nie jest zainstalowany. Zainstaluj Node.js i npm najpierw."
        exit 1
    fi
fi

# Start tunnel
echo "Uruchamianie tunelu..."
lt --port $PORT --subdomain $SUBDOMAIN --print-requests
EOF

# Make scripts executable
chmod +x scripts/*.sh

log_success "Skrypty pomocnicze utworzone"

# Step 6: Set proper permissions
log_info "Ustawianie uprawnień..."
chown -R $SUDO_USER:$SUDO_USER . 2>/dev/null || chown -R 1000:1000 . 2>/dev/null || true
chmod -R 755 .
chmod 600 .env
chmod +x install.sh

log_success "Uprawnienia ustawione"

# Step 7: Check Docker
log_info "Sprawdzanie Docker..."
if ! command -v docker &> /dev/null; then
    log_error "Docker nie jest zainstalowany!"
    log_info "Uruchom './install.sh' aby zainstalować Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    log_error "Docker Compose nie jest zainstalowany!"
    log_info "Uruchom './install.sh' aby zainstalować Docker Compose"
    exit 1
fi

log_success "Docker i Docker Compose są zainstalowane"

echo ""
log_success "🎉 NAPRAWA ZAKOŃCZONA POMYŚLNIE!"
echo ""
echo "Następne kroki:"
echo "1. ./install.sh                      # uruchom instalator (jeśli potrzebujesz)"
echo "2. scripts/show-info.sh             # wyświetl dane dostępowe"
echo "3. docker-compose up -d             # uruchom serwisy"
echo "4. scripts/start-tunnel.sh &        # uruchom tunelowanie (w tle)"
echo ""
echo "Aplikacja będzie dostępna pod adresem:"
echo "🌐 https://eqtrader.loca.lt"
echo ""
echo "Aby wyświetlić dane dostępowe w przyszłości:"
echo "./scripts/show-info.sh"
echo ""
