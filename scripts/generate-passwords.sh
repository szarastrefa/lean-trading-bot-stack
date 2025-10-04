#!/bin/bash

# LEAN Trading Bot Stack - Password Generator
# Generates new random passwords for existing installation
# Author: @szarastrefa

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

echo "========================================"
echo "   🔐 LEAN Trading Bot - Generator Haseł"
echo "========================================"
echo ""

if [ ! -f ".env" ]; then
    echo "❌ Plik .env nie istnieje!"
    echo "Uruchom najpierw ./install.sh"
    exit 1
fi

log_warning "To wygeneruje NOWE hasła i zastąpi obecne!"
log_warning "Upewnij się, że masz backup obecnych danych."
echo ""
read -p "Czy kontynuować? (y/N): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Anulowano."
    exit 0
fi

# Create backup of current .env
cp .env .env.backup-$(date +%Y%m%d-%H%M%S)
log_success "Utworzono backup pliku .env"

# Generate new passwords
log_info "Generowanie nowych haseł..."

NEW_POSTGRES_PASSWORD=$(generate_password 24)
NEW_REDIS_PASSWORD=$(generate_password 16)
NEW_FLASK_SECRET=$(generate_token 32)
NEW_JWT_SECRET=$(generate_token 24)
NEW_ADMIN_PASSWORD=$(generate_password 12)
NEW_SESSION_SECRET=$(generate_token 16)

# Update .env file
log_info "Aktualizowanie pliku .env..."

sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_POSTGRES_PASSWORD/" .env
sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=$NEW_REDIS_PASSWORD/" .env
sed -i "s/^FLASK_SECRET_KEY=.*/FLASK_SECRET_KEY=$NEW_FLASK_SECRET/" .env
sed -i "s/^JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$NEW_JWT_SECRET/" .env
sed -i "s/^ADMIN_PASSWORD=.*/ADMIN_PASSWORD=$NEW_ADMIN_PASSWORD/" .env
sed -i "s/^SESSION_SECRET=.*/SESSION_SECRET=$NEW_SESSION_SECRET/" .env

# Update timestamp
echo "# Last password update: $(date)" >> .env

log_success "Plik .env zaktualizowany"

# Create new credentials backup
CREDENTIALS_FILE="$HOME/.lean-bot-credentials-$(date +%Y%m%d-%H%M%S)"
cat > "$CREDENTIALS_FILE" << EOF
# LEAN Trading Bot Stack - New Credentials
# Generated: $(date)
# Project: $PWD

========================================
   LEAN Trading Bot - NOWE HASŁA
========================================

🔐 NOWE DANE LOGOWANIA:
   Username: admin
   Password: $NEW_ADMIN_PASSWORD

🗄️ NOWA BAZA DANYCH:
   Host: localhost:5432
   Database: lean_trading
   User: leanuser
   Password: $NEW_POSTGRES_PASSWORD

🔄 NOWY REDIS:
   Host: localhost:6379
   Password: $NEW_REDIS_PASSWORD

🔑 NOWE KLUCZE:
   Flask Secret: $NEW_FLASK_SECRET
   JWT Secret: $NEW_JWT_SECRET
   Session Secret: $NEW_SESSION_SECRET

⚠️ WAŻNE:
   - Restart aplikacji wymagany: docker-compose restart
   - Wszystkie sesje użytkowników zostaną wylogowane
   - Zaktualizuj hasła w systemach zewnętrznych

EOF

chmod 600 "$CREDENTIALS_FILE"
log_success "Backup nowych haseł: $CREDENTIALS_FILE"

echo ""
echo "========================================"
echo "   ✅ HASŁA ZOSTAŁY WYGENEROWANE!"
echo "========================================"
echo ""
echo "🔐 NOWE HASŁA:"
echo "   👤 Admin: admin / $NEW_ADMIN_PASSWORD"
echo "   🗄️ PostgreSQL: leanuser / $NEW_POSTGRES_PASSWORD"
echo "   🔄 Redis: $NEW_REDIS_PASSWORD"
echo ""
echo "💾 BACKUP: $CREDENTIALS_FILE"
echo ""
echo "⚠️  RESTART WYMAGANY:"
echo "   docker-compose restart"
echo ""
echo "🛠️  LUB PEŁNY RESTART:"
echo "   docker-compose down && docker-compose up -d"
echo "========================================"

read -p "Czy zrestartować aplikację teraz? (y/N): " restart_now

if [[ $restart_now =~ ^[Yy]$ ]]; then
    log_info "Restartowanie aplikacji..."
    docker-compose restart
    log_success "Aplikacja zrestartowana z nowymi hasłami!"
else
    log_warning "Pamiętaj o ręcznym restarcie: docker-compose restart"
fi

echo ""
log_success "Generator haseł zakończony pomyślnie!"
