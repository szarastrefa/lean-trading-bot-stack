#!/bin/bash

# LEAN Trading Bot Stack - Interaktywny Instalator
# Autor: LEAN Trading Bot Stack Team
# Licencja: Apache 2.0

set -e

# Kolory do wyświetlania
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funkcje pomocnicze
print_header() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "               LEAN Trading Bot Stack Installer"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[KROK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUKCES]${NC} $1"
}

print_error() {
    echo -e "${RED}[BŁĄD]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[OSTRZEŻENIE]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Sprawdzanie wymagań systemowych
check_requirements() {
    print_step "Sprawdzanie wymagań systemowych..."
    
    # Sprawdzenie systemu operacyjnego
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_info "Wykryto system: Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_info "Wykryto system: macOS"
    else
        print_error "Nieobsługiwany system operacyjny: $OSTYPE"
        print_info "Obsługiwane systemy: Linux, macOS"
        exit 1
    fi
    
    # Sprawdzenie dostępności curl
    if ! command -v curl &> /dev/null; then
        print_error "curl nie jest zainstalowany. Zainstaluj curl i spróbuj ponownie."
        exit 1
    fi
    
    # Sprawdzenie dostępności git
    if ! command -v git &> /dev/null; then
        print_error "git nie jest zainstalowany. Zainstaluj git i spróbuj ponownie."
        exit 1
    fi
    
    print_success "Wymagania systemowe spełnione"
}

# Instalacja Docker
install_docker() {
    print_step "Sprawdzanie instalacji Docker..."
    
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        print_success "Docker już zainstalowany"
        return 0
    fi
    
    echo -e "${YELLOW}Docker nie jest zainstalowany. Czy chcesz go zainstalować? (y/n):${NC}"
    read -r install_docker_choice
    
    if [[ $install_docker_choice =~ ^[Yy]$ ]]; then
        print_step "Instalowanie Docker..."
        
        if [[ "$OS" == "linux" ]]; then
            # Instalacja Docker na Linux
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            
            # Instalacja Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            
            rm get-docker.sh
            
        elif [[ "$OS" == "macos" ]]; then
            print_info "Na macOS zalecamy instalację Docker Desktop z https://www.docker.com/products/docker-desktop"
            print_error "Zainstaluj Docker Desktop i uruchom ponownie instalator"
            exit 1
        fi
        
        print_success "Docker zainstalowany. RESTART może być wymagany dla grupy docker."
        print_warning "Jeśli otrzymujesz błędy uprawnień, wykonaj: newgrp docker"
    else
        print_error "Docker jest wymagany do uruchomienia projektu"
        exit 1
    fi
}

# Konfiguracja tunelowania
setup_tunneling() {
    print_step "Konfiguracja tunelowania..."
    
    echo -e "${CYAN}Wybierz opcję dostępu do aplikacji:${NC}"
    echo "1) Tylko lokalne (localhost)"
    echo "2) Tunelowanie przez internet"
    echo "3) Własna domena/serwer"
    
    read -p "Wybór (1-3): " access_choice
    
    case $access_choice in
        1)
            echo "TUNNEL_TYPE=none" >> .env
            print_info "Konfiguracja: tylko dostęp lokalny"
            ;;
        2)
            setup_tunnel_service
            ;;
        3)
            echo "TUNNEL_TYPE=domain" >> .env
            read -p "Podaj domenę (np. yourdomain.com): " domain_name
            echo "DOMAIN_NAME=$domain_name" >> .env
            print_info "Konfiguracja: własna domena $domain_name"
            print_warning "Skonfiguruj DNS A record wskazujący na IP tego serwera"
            ;;
        *)
            print_error "Nieprawidłowy wybór"
            exit 1
            ;;
    esac
}

# Konfiguracja usług tunelowania
setup_tunnel_service() {
    echo -e "${CYAN}Wybierz usługę tunelowania:${NC}"
    echo "1) Ngrok (najpopularniejszy)"
    echo "2) LocalTunnel (darmowy)"
    echo "3) Serveo (SSH-based)"
    echo "4) Cloudflare Tunnel (enterprise)"
    echo "5) PageKite (niezawodny)"
    echo "6) Telebit (open source)"
    
    read -p "Wybór (1-6): " tunnel_choice
    
    case $tunnel_choice in
        1)
            setup_ngrok
            ;;
        2)
            setup_localtunnel
            ;;
        3)
            setup_serveo
            ;;
        4)
            setup_cloudflare_tunnel
            ;;
        5)
            setup_pagekite
            ;;
        6)
            setup_telebit
            ;;
        *)
            print_error "Nieprawidłowy wybór"
            exit 1
            ;;
    esac
}

# Konfiguracja Ngrok
setup_ngrok() {
    echo "TUNNEL_TYPE=ngrok" >> .env
    read -p "Podaj Ngrok Auth Token (z https://dashboard.ngrok.com): " ngrok_token
    echo "NGROK_AUTH_TOKEN=$ngrok_token" >> .env
    print_success "Konfiguracja Ngrok zakończona"
}

# Konfiguracja LocalTunnel
setup_localtunnel() {
    echo "TUNNEL_TYPE=localtunnel" >> .env
    read -p "Podaj subdomenę (opcjonalne, ENTER aby losowa): " lt_subdomain
    if [[ -n "$lt_subdomain" ]]; then
        echo "LOCALTUNNEL_SUBDOMAIN=$lt_subdomain" >> .env
    fi
    print_success "Konfiguracja LocalTunnel zakończona"
}

# Konfiguracja Serveo
setup_serveo() {
    echo "TUNNEL_TYPE=serveo" >> .env
    read -p "Podaj subdomenę (opcjonalne, ENTER aby losowa): " serveo_subdomain
    if [[ -n "$serveo_subdomain" ]]; then
        echo "SERVEO_SUBDOMAIN=$serveo_subdomain" >> .env
    fi
    print_success "Konfiguracja Serveo zakończona"
}

# Konfiguracja Cloudflare Tunnel
setup_cloudflare_tunnel() {
    echo "TUNNEL_TYPE=cloudflare" >> .env
    read -p "Podaj Cloudflare Tunnel Token: " cf_token
    echo "CLOUDFLARE_TUNNEL_TOKEN=$cf_token" >> .env
    print_success "Konfiguracja Cloudflare Tunnel zakończona"
    print_info "Pamiętaj o skonfigurowaniu DNS w Cloudflare Dashboard"
}

# Konfiguracja PageKite
setup_pagekite() {
    echo "TUNNEL_TYPE=pagekite" >> .env
    read -p "Podaj PageKite kite name: " pk_kite
    read -p "Podaj PageKite secret: " pk_secret
    echo "PAGEKITE_KITE=$pk_kite" >> .env
    echo "PAGEKITE_SECRET=$pk_secret" >> .env
    print_success "Konfiguracja PageKite zakończona"
}

# Konfiguracja Telebit
setup_telebit() {
    echo "TUNNEL_TYPE=telebit" >> .env
    read -p "Podaj Telebit token (opcjonalne): " telebit_token
    if [[ -n "$telebit_token" ]]; then
        echo "TELEBIT_TOKEN=$telebit_token" >> .env
    fi
    print_success "Konfiguracja Telebit zakończona"
}

# Konfiguracja zmiennych środowiskowych
setup_environment() {
    print_step "Konfiguracja zmiennych środowiskowych..."
    
    if [[ ! -f .env ]]; then
        cp .env.example .env
    fi
    
    # Generowanie sekretów
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d /=+ | cut -c -16)
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d /=+ | cut -c -16)
    FLASK_SECRET_KEY=$(openssl rand -base64 32)
    
    # Aktualizacja .env
    sed -i.bak "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
    sed -i.bak "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" .env
    sed -i.bak "s/FLASK_SECRET_KEY=.*/FLASK_SECRET_KEY=$FLASK_SECRET_KEY/" .env
    
    rm .env.bak
    
    print_success "Zmienne środowiskowe skonfigurowane"
    print_warning "Edytuj plik .env aby dodać klucze API brokerów"
}

# Budowanie i uruchamianie kontenerów
start_services() {
    print_step "Budowanie i uruchamianie kontenerów..."
    
    # Budowanie obrazów
    docker-compose build
    
    # Uruchamianie usług podstawowych
    docker-compose up -d postgres redis
    
    # Oczekanie na uruchomienie bazy danych
    print_info "Oczekiwanie na uruchomienie bazy danych..."
    sleep 10
    
    # Uruchamianie pozostałych usług
    if [[ "$(grep TUNNEL_TYPE .env | cut -d= -f2)" != "none" ]]; then
        docker-compose --profile tunnel up -d
    else
        docker-compose up -d
    fi
    
    print_success "Wszystkie usługi uruchomione"
}

# Wyświetlanie informacji końcowych
show_final_info() {
    print_step "Instalacja zakończona!"
    
    echo -e "${GREEN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    INSTALACJA ZAKOŃCZONA"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    
    echo -e "${CYAN}Dostępne usługi:${NC}"
    echo "• Web UI: http://localhost:3000"
    echo "• API Backend: http://localhost:5000"
    echo "• ML Jupyter Lab: http://localhost:8888"
    echo "• PostgreSQL: localhost:5432"
    echo "• Redis: localhost:6379"
    
    if [[ "$(grep TUNNEL_TYPE .env | cut -d= -f2)" != "none" ]]; then
        echo -e "${YELLOW}• Tunel będzie dostępny po uruchomieniu${NC}"
    fi
    
    echo -e "\n${BLUE}Przydatne komendy:${NC}"
    echo "• Sprawdź status: docker-compose ps"
    echo "• Zobacz logi: docker-compose logs -f"
    echo "• Zatrzymaj: docker-compose down"
    echo "• Restart: docker-compose restart"
    
    echo -e "\n${PURPLE}Następne kroki:${NC}"
    echo "1. Edytuj plik .env i dodaj klucze API brokerów"
    echo "2. Sprawdź dokumentację w folderze docs/"
    echo "3. Uruchom przykładową strategię"
    
    echo -e "\n${RED}WAŻNE:${NC}"
    echo "• Nigdy nie commituj pliku .env do repozytorium"
    echo "• Używaj tylko na papierowym tradingu do testów"
    echo "• Przeczytaj docs/SECURITY.md przed produkcją"
}

# Główna funkcja
main() {
    print_header
    
    # Sprawdzenie czy jesteśmy w odpowiednim katalogu
    if [[ ! -f docker-compose.yml ]]; then
        print_error "Uruchom instalator w katalogu głównym projektu (gdzie jest docker-compose.yml)"
        exit 1
    fi
    
    check_requirements
    install_docker
    setup_tunneling
    setup_environment
    start_services
    show_final_info
    
    print_success "Instalator zakończony pomyślnie!"
}

# Obsługa przerwania
trap 'print_error "Instalacja przerwana przez użytkownika"; exit 1' INT

# Uruchomienie głównej funkcji
main "$@"