# LEAN Trading Bot Stack 🚀

> **Status**: ✅ NAPRAWIONY - Problem z brakującymi plikami nginx rozwiązany

Kompletny stack do automatycznego tradingu z wykorzystaniem QuantConnect LEAN Engine, Docker i tunelowaniem przez internet.

## 🎯 Funkcjonalności

- **QuantConnect LEAN Engine** - Zaawansowany silnik do algorytmicznego tradingu
- **Docker Stack** - Konteneryzacja wszystkich serwisów (PostgreSQL, Redis, Nginx, Flask)
- **Web Dashboard** - Panel kontrolny z wizualizacjami
- **Tunelowanie** - Dostęp przez internet (LocalTunnel, Ngrok, Cloudflare)
- **API REST** - Interfejs programistyczny
- **Paper Trading** - Bezpieczne testowanie strategii
- **Automatyczne backupy** - Zabezpieczenie danych

## 🛠️ Szybka instalacja

### ⚡ Automatyczna naprawa (ZALECANE)

Jeśli masz problemy z instalacją, użyj skryptu naprawczego:

```bash
# Sklonuj repozytorium
git clone https://github.com/szarastrefa/lean-trading-bot-stack.git
cd lean-trading-bot-stack

# Uruchom skrypt naprawczy
sudo chmod +x scripts/fix-installation.sh
sudo ./scripts/fix-installation.sh

# Uruchom instalację
./install.sh
```

### 📋 Standardowa instalacja

```bash
# 1. Sklonuj repozytorium
git clone https://github.com/szarastrefa/lean-trading-bot-stack.git
cd lean-trading-bot-stack

# 2. Uruchom instalator
./install.sh

# 3. Skonfiguruj QuantConnect API w .env
nano .env

# 4. Uruchom serwisy
docker-compose up -d

# 5. Uruchom tunelowanie (opcjonalne)
scripts/start-tunnel.sh &
```

## 🌐 Dostęp do aplikacji

Po instalacji aplikacja będzie dostępna pod adresami:

- **🌐 Aplikacja główna**: https://eqtrader.loca.lt
- **📊 Dashboard**: https://eqtrader.loca.lt/dashboard  
- **🔗 API**: https://eqtrader.loca.lt/api
- **📚 Dokumentacja API**: https://eqtrader.loca.lt/docs

## 🔐 Dane dostępowe

### Domyślne logowanie
- **Username**: `admin`
- **Password**: `admin123!@#` ⚠️ *Zmień po pierwszym logowaniu!*

### Wygenerowane hasła (sprawdź w `.env`)
- **PostgreSQL**: Automatycznie wygenerowane 32-znakowe hasło
- **Redis**: Automatycznie wygenerowane 16-znakowe hasło  
- **Flask Secret**: Automatycznie wygenerowany 64-znakowy klucz
- **JWT Secret**: Automatycznie wygenerowany token

Aby wyświetlić wszystkie dane dostępowe:
```bash
./scripts/show-info.sh
```

## ⚙️ Konfiguracja

### 1. QuantConnect API

Uzupełnij dane w pliku `.env`:
```bash
QC_API_ACCESS_TOKEN=your_actual_token_here
QC_USER_ID=your_actual_user_id_here
```

Aby otrzymać klucze:
1. Zarejestruj się na https://www.quantconnect.com
2. Przejdź do Account → API
3. Skopiuj Access Token i User ID

### 2. Tunelowanie (opcjonalne)

Dostępne opcje:
- **LocalTunnel** (domyślne, darmowe)
- **Ngrok** (stabilniejsze, wymagana rejestracja)
- **Cloudflare Tunnel** (enterprise)

Dla Ngrok uzupełnij:
```bash
NGROK_AUTH_TOKEN=your_ngrok_token
```

## 🔧 Rozwiązywanie problemów

### Problem: `path "/docker/nginx" not found`

**Rozwiązanie**:
```bash
sudo ./scripts/fix-installation.sh
./install.sh
```

### Problem: Błędy uprawnień Docker

**Rozwiązanie**:
```bash
sudo usermod -aG docker $USER
newgrp docker
# lub wyloguj się i zaloguj ponownie
```

### Problem: Kontener nie startuje

**Diagnostyka**:
```bash
docker-compose ps
docker-compose logs [nazwa-serwisu]
```

## 📁 Struktura projektu

```
lean-trading-bot-stack/
├── .env                    # Zmienne środowiskowe
├── .env.fixed              # Wzorcowy plik .env z hasłami
├── docker-compose.yml      # Konfiguracja kontenerów
├── install.sh              # Główny instalator
├── docker/
│   ├── nginx/              # Konfiguracja serwera web
│   ├── lean/               # LEAN Engine
│   └── tunnel/             # Tunelowanie
├── scripts/
│   ├── fix-installation.sh # Skrypt naprawczy ✨
│   ├── show-info.sh        # Wyświetl dane dostępowe
│   └── start-tunnel.sh     # Uruchom tunelowanie
├── webui/                  # Interfejs webowy
└── docs/                   # Dokumentacja
```

## 🛠️ Przydatne polecenia

```bash
# Zarządzanie serwisami
docker-compose up -d          # Uruchom wszystkie serwisy
docker-compose down           # Zatrzymaj wszystkie serwisy
docker-compose restart        # Restartuj wszystkie serwisy
docker-compose logs -f        # Zobacz logi na żywo

# Zarządzanie pojedynczymi serwisami
docker-compose restart nginx  # Restartuj tylko nginx
docker-compose logs web       # Logi aplikacji web

# Diagnostyka
docker-compose ps             # Status kontenerów
docker system df              # Użycie miejsca Docker
docker system prune           # Wyczyść nieużywane dane

# Backup
docker-compose exec postgres pg_dump -U lean_user lean_trading > backup.sql

# Przywracanie
docker-compose exec -T postgres psql -U lean_user lean_trading < backup.sql
```

## 🔒 Bezpieczeństwo

- ✅ **Automatycznie generowane hasła** z wysoką entropią
- ✅ **Separacja kontenerów** Docker
- ✅ **Nginx reverse proxy** z security headers
- ✅ **Paper trading domyślnie** dla bezpieczeństwa
- ⚠️ **Zmień hasło admin** po pierwszym logowaniu
- ⚠️ **Używaj HTTPS** w produkcji
- ⚠️ **Regularnie aktualizuj** hasła i tokeny

## 📊 Monitoring

```bash
# Status wszystkich serwisów
docker-compose ps

# Użycie zasobów
docker stats

# Logi błędów nginx
docker-compose logs nginx | grep error

# Monitoring bazy danych
docker-compose exec postgres psql -U lean_user -d lean_trading -c "SELECT * FROM pg_stat_activity;"
```

## 🤝 Wsparcie

Jeśli masz problemy:

1. **Uruchom skrypt naprawczy**: `sudo ./scripts/fix-installation.sh`
2. **Sprawdź logi**: `docker-compose logs -f`
3. **Sprawdź status**: `docker-compose ps`
4. **Wyświetl konfigurację**: `./scripts/show-info.sh`

## 📚 Dokumentacja

- [QuantConnect LEAN](https://www.quantconnect.com/docs/v2/lean-cli)
- [Docker Compose](https://docs.docker.com/compose/)
- [LocalTunnel](https://localtunnel.github.io/www/)
- [Nginx Configuration](https://nginx.org/en/docs/)

## 📝 Changelog

### v1.1 (2025-10-04)
- ✅ **NAPRAWIONO**: Problem z brakującymi plikami nginx
- ➕ Dodano automatyczny skrypt naprawczy
- ➕ Automatyczne generowanie bezpiecznych haseł
- ➕ Ulepszona dokumentacja i instrukcje
- ➕ Dodano skrypty pomocnicze
- 🔧 Poprawiono konfigurację nginx
- 🔒 Zwiększone bezpieczeństwo

### v1.0
- 🎉 Pierwsze wydanie
- 🐳 Docker stack
- 🌐 Tunelowanie przez internet
- 📊 Web dashboard

---

**Autor**: [@szarastrefa](https://github.com/szarastrefa)  
**Licencja**: MIT  
**Status**: ✅ Aktywnie utrzymywane