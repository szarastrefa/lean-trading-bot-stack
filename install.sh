#!/bin/bash

# LEAN Trading Bot Stack Installer - Enhanced Version
# Generates random passwords during installation
# Author: @szarastrefa
# Version: 2.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log_step() {
    echo -e "${BLUE}[KROK]${NC} $1"
}

# Generate secure random password
generate_password() {
    local length=${1:-24}
    openssl rand -base64 32 | tr -d "/+=" | cut -c1-$length
}

# Generate hex token
generate_token() {
    local length=${1:-32}
    openssl rand -hex $length
}

echo "══════════════════════════════════════════════════════════════════"
echo "               LEAN Trading Bot Stack Installer v2.0"
echo "              🔐 Z automatycznym generowaniem haseł"
echo "══════════════════════════════════════════════════════════════════"
echo ""

# Check requirements
log_step "Sprawdzanie wymagań systemowych..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    log_info "Wykryto system: Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    log_info "Wykryto system: macOS"
else
    log_error "Nieobsługiwany system operacyjny: $OSTYPE"
    exit 1
fi

log_success "Wymagania systemowe spełnione"

# Check Docker installation
log_step "Sprawdzanie instalacji Docker..."

if command -v docker &> /dev/null; then
    log_success "Docker już zainstalowany"
else
    log_warning "Docker nie jest zainstalowany. Czy chcesz go zainstalować? (y/n):"
    read -r install_docker
    if [[ $install_docker =~ ^[Yy]$ ]]; then
        log_step "Instalowanie Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        
        # Add user to docker group
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo usermod -aG docker $USER
            log_warning "Restart może być wymagany dla grupy docker"
            log_warning "Jeśli otrzymujesz błędy uprawnień, wykonaj: newgrp docker"
        fi
        
        log_success "Docker zainstalowany"
    else
        log_error "Docker jest wymagany do działania aplikacji"
        exit 1
    fi
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    log_warning "Docker Compose nie znaleziony, instalowanie..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Generate secure passwords
log_step "Generowanie bezpiecznych haseł..."

POSTGRES_PASSWORD=$(generate_password 24)
REDIS_PASSWORD=$(generate_password 16)
FLASK_SECRET=$(generate_token 32)
JWT_SECRET=$(generate_token 24)
ADMIN_PASSWORD=$(generate_password 12)
SESSION_SECRET=$(generate_token 16)

log_success "Bezpieczne hasła wygenerowane"

# Tunneling configuration
log_step "Konfiguracja tunelowania..."

echo "Wybierz opcję dostępu do aplikacji:"
echo "1) Tylko lokalne (localhost)"
echo "2) Tunelowanie przez internet"
echo "3) Własna domena/serwer"
read -p "Wybór (1-3): " tunnel_choice

TUNNEL_SERVICE=""
TUNNEL_SUBDOMAIN=""
APP_URL="http://localhost"

case $tunnel_choice in
    1)
        log_info "Wybrano dostęp lokalny"
        APP_URL="http://localhost"
        ;;
    2)
        echo "Wybierz usługę tunelowania:"
        echo "1) Ngrok (najpopularniejszy)"
        echo "2) LocalTunnel (darmowy)"
        echo "3) Serveo (SSH-based)"
        echo "4) Cloudflare Tunnel (enterprise)"
        echo "5) PageKite (niezawodny)"
        echo "6) Telebit (open source)"
        read -p "Wybór (1-6): " tunnel_service_choice
        
        case $tunnel_service_choice in
            1) TUNNEL_SERVICE="ngrok" ;;
            2) TUNNEL_SERVICE="localtunnel" ;;
            3) TUNNEL_SERVICE="serveo" ;;
            4) TUNNEL_SERVICE="cloudflare" ;;
            5) TUNNEL_SERVICE="pagekite" ;;
            6) TUNNEL_SERVICE="telebit" ;;
            *) TUNNEL_SERVICE="localtunnel" ;;
        esac
        
        read -p "Podaj subdomenę (opcjonalne, ENTER aby losowa): " custom_subdomain
        if [ -n "$custom_subdomain" ]; then
            TUNNEL_SUBDOMAIN="$custom_subdomain"
        else
            TUNNEL_SUBDOMAIN="lean-$(openssl rand -hex 4)"
        fi
        
        if [ "$TUNNEL_SERVICE" = "localtunnel" ]; then
            APP_URL="https://${TUNNEL_SUBDOMAIN}.loca.lt"
        elif [ "$TUNNEL_SERVICE" = "ngrok" ]; then
            APP_URL="https://${TUNNEL_SUBDOMAIN}.ngrok.io"
        else
            APP_URL="https://${TUNNEL_SUBDOMAIN}.example.com"
        fi
        
        log_success "Konfiguracja ${TUNNEL_SERVICE} zakończona"
        ;;
    3)
        read -p "Podaj własną domenę (np. trading.yourdomain.com): " custom_domain
        APP_URL="https://$custom_domain"
        log_success "Konfiguracja własnej domeny zakończona"
        ;;
    *)
        log_warning "Nieprawidłowy wybór, używanie domyślnego (localhost)"
        APP_URL="http://localhost"
        ;;
esac

# Create environment file with generated passwords
log_step "Konfiguracja zmiennych środowiskowych..."

cat > .env << EOF
# LEAN Trading Bot Stack - Environment Configuration
# Generated: $(date)
# 🔐 All passwords are randomly generated for security

# ===== DATABASE CONFIGURATION =====
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_USER=leanuser
POSTGRES_DB=lean_trading
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# ===== REDIS CONFIGURATION =====
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_HOST=redis
REDIS_PORT=6379

# ===== FLASK APPLICATION =====
FLASK_SECRET_KEY=$FLASK_SECRET
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
FLASK_ENV=production

# ===== ADMIN CREDENTIALS =====
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$ADMIN_PASSWORD
ADMIN_EMAIL=admin@localhost

# ===== QUANTCONNECT API =====
QC_API_ACCESS_TOKEN=your_quantconnect_token_here
QC_USER_ID=your_quantconnect_user_id

# ===== TUNNELING SERVICES =====
TUNNEL_SERVICE=$TUNNEL_SERVICE
TUNNEL_SUBDOMAIN=$TUNNEL_SUBDOMAIN
NGROK_AUTH_TOKEN=
CLOUDFLARE_TUNNEL_TOKEN=

# ===== APPLICATION URLS =====
APP_URL=$APP_URL
API_BASE_URL=http://localhost:5000

# ===== LEAN ENGINE CONFIGURATION =====
LEAN_ENGINE_HOST=lean_engine
LEAN_ENGINE_PORT=8080
LEAN_DATA_FOLDER=/data
LEAN_OUTPUT_FOLDER=/output

# ===== SECURITY =====
JWT_SECRET_KEY=$JWT_SECRET
SESSION_SECRET=$SESSION_SECRET
SESSION_TIMEOUT=3600
SSL_VERIFY=true

# ===== LOGGING =====
LOG_LEVEL=INFO
LOG_FILE=/logs/trading.log
LOG_ROTATION=true
LOG_MAX_SIZE=100MB

# ===== TRADING CONFIGURATION =====
DEFAULT_CASH=100000
DEFAULT_CURRENCY=USD
PAPER_TRADING=true
RISK_MANAGEMENT=true
MAX_DRAWDOWN=0.20

# ===== BACKUP CONFIGURATION =====
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=30

# ===== DOCKER CONFIGURATION =====
DOCKER_COMPOSE_PROJECT_NAME=lean_trading_stack
DOCKER_REGISTRY=
DOCKER_TAG=latest

# ===== MONITORING =====
METRICS_ENABLED=true
METRICS_PORT=9090
HEALTH_CHECK_INTERVAL=30

EOF

chmod 600 .env
log_success "Zmienne środowiskowe skonfigurowane"

# Create credentials backup
CREDENTIALS_FILE="$HOME/.lean-bot-credentials-$(date +%Y%m%d-%H%M%S)"
cat > "$CREDENTIALS_FILE" << EOF
# LEAN Trading Bot Stack - Backup Credentials
# Generated: $(date)
# Project: $PWD

========================================
   LEAN Trading Bot - DANE DOSTĘPOWE
========================================

🌐 DOSTĘP DO APLIKACJI:
   URL: $APP_URL
   Dashboard: $APP_URL/dashboard
   API: $APP_URL/api

🔐 DANE LOGOWANIA:
   Username: admin
   Password: $ADMIN_PASSWORD

🗄️ BAZA DANYCH:
   Host: localhost:5432
   Database: lean_trading
   User: leanuser
   Password: $POSTGRES_PASSWORD

🔄 REDIS:
   Host: localhost:6379
   Password: $REDIS_PASSWORD

🔑 INNE KLUCZE:
   Flask Secret: $FLASK_SECRET
   JWT Secret: $JWT_SECRET
   Session Secret: $SESSION_SECRET

⚠️ BEZPIECZEŃSTWO:
   - Zmień hasło administratora po pierwszym logowaniu
   - Uzupełnij dane QuantConnect w pliku .env
   - Regularnie aktualizuj hasła produkcyjne
   - Ten plik powinien być przechowywany w bezpiecznym miejscu

EOF

chmod 600 "$CREDENTIALS_FILE"
log_success "Backup danych dostępowych utworzony: $CREDENTIALS_FILE"

if [ -n "$QC_API_ACCESS_TOKEN" ] && [ "$QC_API_ACCESS_TOKEN" != "your_quantconnect_token_here" ]; then
    log_success "Dane QuantConnect skonfigurowane"
else
    log_warning "Edytuj plik .env aby dodać klucze API brokerów"
fi

# Build and start containers
log_step "Budowanie i uruchamianie kontenerów..."

# Remove old containers and images
docker-compose down --remove-orphans 2>/dev/null || true
docker system prune -f 2>/dev/null || true

# Start services
if docker-compose up --build -d; then
    log_success "Kontenery uruchomione pomyślnie"
else
    log_error "Błąd podczas uruchamiania kontenerów"
    log_info "Sprawdź logi: docker-compose logs -f"
    exit 1
fi

# Wait for services to be ready
log_step "Oczekiwanie na gotowość serwisów..."
sleep 10

# Check service health
if docker-compose ps | grep -q "Up"; then
    log_success "Serwisy są uruchomione"
else
    log_warning "Niektóre serwisy mogą nie działać poprawnie"
    log_info "Sprawdź status: docker-compose ps"
fi

# Display success message with credentials
echo ""
echo "========================================"
echo "   🎉 INSTALACJA ZAKOŃCZONA POMYŚLNIE!"
echo "========================================"
echo ""
echo "🌐 APLIKACJA DOSTĘPNA POD:"
echo "   $APP_URL"
echo "   Dashboard: $APP_URL/dashboard"
echo "   API: $APP_URL/api"
echo ""
echo "🔐 NOWE LOSOWE HASŁA:"
echo "   👤 Admin: admin / $ADMIN_PASSWORD"
echo "   🗄️ PostgreSQL: leanuser / $POSTGRES_PASSWORD"
echo "   🔄 Redis: $REDIS_PASSWORD"
echo ""
echo "💾 BACKUP DANYCH:"
echo "   Plik: $CREDENTIALS_FILE"
echo ""
echo "⚠️  ZAPISZ TE HASŁA BEZPIECZNIE!"
echo "   Nie będą ponownie wyświetlone"
echo ""
echo "🛠️  PRZYDATNE POLECENIA:"
echo "   docker-compose ps              # status kontenerów"
echo "   docker-compose logs -f         # logi na żywo"
echo "   docker-compose restart         # restart serwisów"
echo "   ./scripts/show-info.sh         # pokaż dane dostępowe"
echo ""
if [ "$TUNNEL_SERVICE" = "localtunnel" ]; then
echo "🌐 TUNELOWANIE:"
echo "   Zainstaluj LocalTunnel: npm install -g localtunnel"
echo "   Uruchom tunel: lt --port 80 --subdomain $TUNNEL_SUBDOMAIN"
echo ""
fi
echo "🎯 NASTĘPNE KROKI:"
echo "   1. Uzupełnij dane QuantConnect w .env"
echo "   2. Zmień hasło admin po pierwszym logowaniu"
echo "   3. Skonfiguruj strategie tradingowe"
echo "   4. Uruchom tunelowanie (jeśli wybrane)"
echo ""
echo "========================================"

exit 0
