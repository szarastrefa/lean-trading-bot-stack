# 📦 Instrukcja instalacji LEAN Trading Bot Stack

Szczegółowy przewodnik po instalacji i konfiguracji platformy tradingowej.

## 📝 Spis treści

1. [Wymagania systemowe](#wymagania-systemowe)
2. [Automatyczna instalacja](#automatyczna-instalacja)
3. [Instalacja ręczna](#instalacja-ręczna)
4. [Konfiguracja brokerów](#konfiguracja-brokerów)
5. [Weryfikacja instalacji](#weryfikacja-instalacji)
6. [Rozwiązywanie problemów](#rozwiązywanie-problemów)

## 💻 Wymagania systemowe

### Minimalne wymagania
- **System**: Linux (Ubuntu 20.04+, Debian 10+) lub macOS 10.15+
- **RAM**: 4 GB (8 GB zalecane)
- **Dysk**: 10 GB wolnego miejsca (SSD zalecany)
- **Procesor**: 2 rdzenie (4 rdzenie zalecane)
- **Internet**: Stabilne połączenie (wymagane dla live tradingu)

### Wymagane oprogramowanie
- **Docker** 20.10+
- **Docker Compose** 2.0+
- **Git** 2.0+
- **curl**
- **OpenSSL** (dla generowania kluczy)

## ⚡ Automatyczna instalacja

### Krok 1: Pobranie projektu

```bash
# Klonowanie repozytorium
git clone https://github.com/szarastrefa/lean-trading-bot-stack.git
cd lean-trading-bot-stack

# Nadanie uprawnień wykonywania
chmod +x install.sh
```

### Krok 2: Uruchomienie instalatora

```bash
./install.sh
```

Instalator przeprowadzi Cię przez:
- Sprawdzenie wymagań systemowych
- Instalację Docker (jeśli wymagana)
- Konfigurację tunelowania
- Generowanie kluczy bezpieczeństwa
- Budowanie i uruchomienie kontenerów

### Krok 3: Post-instalacja

Po zakończeniu instalacji:

1. **Edytuj plik `.env`** - dodaj klucze API brokerów
2. **Zrestartuj usługi**: `docker-compose restart`
3. **Sprawdź status**: `docker-compose ps`

## 🔧 Instalacja ręczna

### Krok 1: Instalacja Docker

#### Ubuntu/Debian
```bash
# Aktualizacja pakietów
sudo apt update

# Instalacja Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Dodanie użytkownika do grupy docker
sudo usermod -aG docker $USER

# Instalacja Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Restart sesji lub:
newgrp docker
```

#### macOS
```bash
# Instalacja przez Homebrew
brew install docker docker-compose

# Lub pobierz Docker Desktop
# https://www.docker.com/products/docker-desktop
```

### Krok 2: Konfiguracja środowiska

```bash
# Skopiowanie przykładowej konfiguracji
cp .env.example .env

# Wygenerowanie hasła dla PostgreSQL
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d /=+ | cut -c -16)
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> .env

# Wygenerowanie hasła dla Redis
REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d /=+ | cut -c -16)
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .env

# Wygenerowanie klucza Flask
FLASK_SECRET_KEY=$(openssl rand -base64 32)
echo "FLASK_SECRET_KEY=$FLASK_SECRET_KEY" >> .env
```

### Krok 3: Budowanie i uruchomienie

```bash
# Budowanie obrazów
docker-compose build

# Uruchomienie usług bazowych
docker-compose up -d postgres redis

# Oczekiwanie na uruchomienie bazy
sleep 10

# Uruchomienie pozostałych usług
docker-compose up -d
```

## 🏦 Konfiguracja brokerów

### Przygotowanie kluczy API

1. Załóż konta u wybranych brokerów
2. Wygeneruj klucze API z odpowiednimi uprawnieniami
3. Dodaj klucze do pliku `.env`

### Przykład konfiguracji Binance

```bash
# W pliku .env
BINANCE_API_KEY=your_actual_binance_api_key
BINANCE_API_SECRET=your_actual_binance_api_secret
BINANCE_TESTNET=true  # Rozpocznij od testnet!
```

### Przykład konfiguracji IC Markets

```bash
# W pliku .env
IC_MARKETS_API_KEY=your_ic_markets_api_key
IC_MARKETS_API_SECRET=your_ic_markets_api_secret
IC_MARKETS_ACCOUNT_ID=your_account_id
IC_MARKETS_ENVIRONMENT=demo  # Rozpocznij od demo!
```

**Więcej szczegółów w [docs/BROKERS.md](./BROKERS.md)**

## ✅ Weryfikacja instalacji

### Sprawdzenie statusów kontenerów

```bash
docker-compose ps
```

Wszystkie usługi powinny mieć status `Up`:

```
NAME              STATUS
lean-engine       Up
webui-backend     Up  
webui-frontend    Up
ml-runtime        Up
postgres-db       Up
redis-cache       Up
nginx-proxy       Up
```

### Test połączeń

```bash
# Test Web UI
curl -f http://localhost:3000

# Test API
curl -f http://localhost:5000/api/health

# Test bazy danych
docker-compose exec postgres psql -U postgres -d trading_bot -c "SELECT 1;"

# Test Redis
docker-compose exec redis redis-cli ping
```

### Sprawdzenie logów

```bash
# Wszystkie logi
docker-compose logs

# Logi konkretnej usługi
docker-compose logs webui-backend

# Logi na żywo
docker-compose logs -f
```

## 🔧 Rozwiązywanie problemów

### Problem: Docker permission denied

```bash
# Rozwiązanie
sudo usermod -aG docker $USER
newgrp docker
# lub zrestartuj sesję
```

### Problem: Port już zajęty

```bash
# Sprawdź co używa portu
sudo netstat -tulpn | grep :3000

# Zmień port w docker-compose.yml lub .env
# Przykład: "3001:3000" zamiast "3000:3000"
```

### Problem: Kontenery nie mogą się połączyć

```bash
# Sprawdzenie sieci Docker
docker network ls
docker network inspect lean-trading-bot-stack_trading-network

# Reset sieci
docker-compose down
docker network prune
docker-compose up -d
```

### Problem: Baza danych nie uruchamia się

```bash
# Sprawdzenie logów PostgreSQL
docker-compose logs postgres

# Reset danych (UWAGA: usuń dane!)
docker-compose down -v
docker-compose up -d
```

### Problem: Brak pamięci lub miejsca na dysku

```bash
# Sprawdzenie zużycia miejsca przez Docker
docker system df

# Czyszczenie nieaktywnych zasobów
docker system prune -a

# Sprawdzenie zużycia pamięci
docker stats
```

### Problem: LEAN Engine nie działa

```bash
# Sprawdzenie konfiguracji LEAN
docker-compose exec lean-engine cat /opt/lean/config/config.json

# Sprawdzenie uprawnień do plików
sudo chown -R $(id -u):$(id -g) ./lean/

# Restart LEAN Engine
docker-compose restart lean-engine
```

### Problem: WebUI nie ładuje się

```bash
# Sprawdzenie build'a React
docker-compose logs webui-frontend

# Przebudowanie frontend
docker-compose build --no-cache webui-frontend
docker-compose up -d webui-frontend
```

## 📊 Monitorowanie

### Status usług w czasie rzeczywistym

```bash
# Ciągłe monitorowanie
watch docker-compose ps

# Statystyki zasobów
docker stats

# Monitorowanie logów
docker-compose logs -f --tail=100
```

### Health Checks

```bash
# Skrypt sprawdzający zdrowie usług
#!/bin/bash
echo "=== HEALTH CHECK ==="
curl -s http://localhost:3000 > /dev/null && echo "WebUI: OK" || echo "WebUI: FAIL"
curl -s http://localhost:5000/api/health > /dev/null && echo "API: OK" || echo "API: FAIL"
docker-compose exec -T redis redis-cli ping > /dev/null && echo "Redis: OK" || echo "Redis: FAIL"
docker-compose exec -T postgres pg_isready > /dev/null && echo "PostgreSQL: OK" || echo "PostgreSQL: FAIL"
```

## 🔐 Bezpieczeństwo

### Podstawowe środki bezpieczeństwa

1. **Nigdy nie commituj .env** do repozytorium
2. **Używaj mocnych haseł** (generowanych automatycznie)
3. **Regularnie aktualizuj** obrazy Docker
4. **Monitoruj logi** pod kątem podejrzanej aktywności
5. **Używaj demo/testnet** do testów

### Aktualizacja systemów

```bash
# Aktualizacja obrazów Docker
docker-compose pull
docker-compose build --no-cache
docker-compose up -d

# Aktualizacja systemu (Ubuntu)
sudo apt update && sudo apt upgrade
```

**Więcej informacji o bezpieczeństwie w [docs/SECURITY.md](./SECURITY.md)**

## 🚑 Wsparcie

Jeśli nadal masz problemy:

1. Sprawdź [Issues na GitHub](https://github.com/szarastrefa/lean-trading-bot-stack/issues)
2. Przeczytaj pozostałą dokumentację w folderze `docs/`
3. Utwórz nowy Issue z szczegółowym opisem problemu

---

**Następny krok**: [Konfiguracja tunelowania](./TUNNELING.md) lub [Konfiguracja brokerów](./BROKERS.md)