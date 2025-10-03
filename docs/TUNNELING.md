# 🌐 Przewodnik po tunelowaniu LEAN Trading Bot Stack

Kompletny przewodnik po konfigurowaniu tunelowania dla udostępnienia aplikacji w internecie.

## 📝 Spis treści

1. [Wprowadzenie do tunelowania](#wprowadzenie-do-tunelowania)
2. [Porównanie usług](#porównanie-usług)
3. [Ngrok](#ngrok)
4. [LocalTunnel](#localtunnel)
5. [Serveo](#serveo)
6. [Cloudflare Tunnel](#cloudflare-tunnel)
7. [PageKite](#pagekite)
8. [Telebit](#telebit)
9. [Własna domena](#własna-domena)
10. [Bezpieczeństwo tunelowania](#bezpieczeństwo-tunelowania)

## 🎆 Wprowadzenie do tunelowania

**Tunelowanie** pozwala na udostępnienie lokalnej aplikacji w internecie bez konieczności konfiguracji routera, firewall'a czy własnego serwera. Jest to szczególnie przydatne dla:

- 📱 **Testów mobilnych** - dostęp do aplikacji z telefonu
- 🤝 **Współpracy** - udostępnianie postepów pracy
- 🔔 **Webhooków** - odbieranie powiadomień od brokerów
- 🌍 **Zdalnego dostępu** - korzystanie z bożu z dowolnego miejsca

## 📋 Porównanie usług

| Usługa | Darmowy plan | Custom domeny | Stabilność | Złożoność | SSL | Zalecenie |
|---------|--------------|---------------|-------------|-------------|-----|----------|
| **Ngrok** | Tak (limit) | Płatne | ⭐⭐⭐⭐⭐ | Łatwa | ✓ | Produkcja |
| **LocalTunnel** | Tak | Nie | ⭐⭐⭐ | Bardzo łatwa | ✓ | Prototypy |
| **Serveo** | Tak | Nie | ⭐⭐ | Łatwa | ✓ | Testy |
| **Cloudflare** | Darmowy | Tak | ⭐⭐⭐⭐⭐ | Średnia | ✓ | Enterprise |
| **PageKite** | Płatny | Tak | ⭐⭐⭐⭐ | Średnia | ✓ | Biznes |
| **Telebit** | Tak | Tak | ⭐⭐⭐ | Średnia | ✓ | Open Source |

## 🚀 Ngrok

**Najbardziej popularny i niezawodny** - zalecany do produkcji.

### Konfiguracja

1. **Rejestracja**: https://dashboard.ngrok.com/signup
2. **Pobranie authtoken**: https://dashboard.ngrok.com/get-started/your-authtoken
3. **Konfiguracja w .env**:

```bash
TUNNEL_TYPE=ngrok
NGROK_AUTH_TOKEN=your_actual_ngrok_auth_token
NGROK_REGION=us  # us, eu, ap, au, sa, jp, in
```

4. **Uruchomienie**:

```bash
# Z docker-compose
docker-compose --profile tunnel up -d

# Lub ręcznie
ngrok http 3000
```

### Zaawansowana konfiguracja Ngrok

```yaml
# docker/tunnel/ngrok.yml
authtoken: your_auth_token
region: us
console_ui: false
log_level: info
log_format: json

tunnels:
  web:
    proto: http
    addr: nginx:80
    bind_tls: true
    inspect: false
  api:
    proto: http
    addr: webui-backend:5000
    subdomain: mybot-api  # Tylko dla płatnych planów
```

### Ngrok CLI komendy

```bash
# Status tuneli
ngrok status

# Lista aktywnych tuneli
ngrok tunnels list

# Web interface (localhost:4040)
ngrok http 3000 --inspect=true

# Custom subdomena (płatne)
ngrok http 3000 --subdomain=mybot

# Basic auth
ngrok http 3000 --basic-auth="user:password"
```

### Zalety Ngrok
- ✓ Bardzo stabilny
- ✓ Łatwa konfiguracja
- ✓ Web interface do debugowania
- ✓ Load balancing
- ✓ Custom domeny (płatne)
- ✓ IP whitelisting (płatne)

### Wady Ngrok
- ✗ Losowe URL na darmowym planie
- ✗ Limit połączeń na darmowym planie
- ✗ Płatne zaawansowane funkcje

## 🌍 LocalTunnel

**Prosty i darmowy** - idealny do szybkich testów.

### Konfiguracja

```bash
TUNNEL_TYPE=localtunnel
LOCALTUNNEL_SUBDOMAIN=mybot  # opcjonalne
```

### Użycie ręczne

```bash
# Instalacja
npm install -g localtunnel

# Podstawowe użycie
lt --port 3000

# Z custom subdomeną
lt --port 3000 --subdomain mybot

# Z lokalnym hostem
lt --port 3000 --local-host 0.0.0.0
```

### W kontenerze Docker

```dockerfile
# docker/tunnel/localtunnel/Dockerfile
FROM node:16-alpine
RUN npm install -g localtunnel
CMD ["lt", "--port", "80", "--host", "nginx"]
```

### Zalety LocalTunnel
- ✓ Kompletnie darmowy
- ✓ Bardzo prosty
- ✓ Możliwość wyboru subdomeny
- ✓ Open source

### Wady LocalTunnel
- ✗ Mniej stabilny
- ✗ Brak zaawansowanych funkcji
- ✗ Czasami wymagane potwierdzenie w przeglądarce

## 🔌 Serveo

**SSH-based tunelowanie** - nie wymaga instalacji.

### Konfiguracja

```bash
TUNNEL_TYPE=serveo
SERVEO_SUBDOMAIN=mybot  # opcjonalne
```

### Użycie ręczne

```bash
# Podstawowe użycie
ssh -R 80:localhost:3000 serveo.net

# Z custom subdomeną
ssh -R mybot:80:localhost:3000 serveo.net

# W tle
ssh -R 80:localhost:3000 serveo.net -o ServerAliveInterval=60 &
```

### Skrypt automatyzujący

```bash
#!/bin/bash
# docker/tunnel/serveo.sh
while true; do
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ServerAliveInterval=60 \
        -R ${SERVEO_SUBDOMAIN:-}:80:nginx:80 \
        serveo.net
    sleep 5
done
```

### Zalety Serveo
- ✓ Nie wymaga rejestracji
- ✓ Nie wymaga instalacji
- ✓ Darmowy
- ✓ SSH-based (bezpieczny)

### Wady Serveo
- ✗ Nieregularne dostępność
- ✗ Brak wsparcia technicznego
- ✗ Ograniczona stabilność

## ☁️ Cloudflare Tunnel

**Enterprise-grade tunelowanie** - najwyższa jakość i bezpieczeństwo.

### Przygotowanie

1. **Konto Cloudflare**: https://dash.cloudflare.com/sign-up
2. **Dodanie domeny** do Cloudflare
3. **Instalacja cloudflared**:

```bash
# Ubuntu/Debian
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# macOS
brew install cloudflared
```

### Konfiguracja tunelu

```bash
# Autoryzacja
cloudflared tunnel login

# Utworzenie tunelu
cloudflared tunnel create mybot

# Pobranie tokenu (skopiuj do .env)
cloudflared tunnel token mybot
```

### Konfiguracja DNS

```bash
# Dodanie rekordu DNS
cloudflared tunnel route dns mybot bot.yourdomain.com
```

### Plik konfiguracyjny

```yaml
# ~/.cloudflared/config.yml
tunnel: mybot
credentials-file: ~/.cloudflared/your-tunnel-id.json

ingress:
  - hostname: bot.yourdomain.com
    service: http://localhost:3000
  - hostname: api.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
```

### Konfiguracja w .env

```bash
TUNNEL_TYPE=cloudflare
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token
```

### Zaawansowane funkcje

```yaml
# Konfiguracja z Access (autoryzacja)
ingress:
  - hostname: bot.yourdomain.com
    service: http://localhost:3000
    originRequest:
      httpHostHeader: bot.yourdomain.com
      access:
        required: true
        teamName: your-team
```

### Zalety Cloudflare Tunnel
- ✓ Bardzo stabilny
- ✓ Darmowy
- ✓ Custom domeny
- ✓ Integracja z Cloudflare Access
- ✓ DDoS protection
- ✓ Global CDN

### Wady Cloudflare Tunnel
- ✗ Wymaga własnej domeny
- ✗ Bardziej skomplikowany setup
- ✗ Zależność od Cloudflare

## 🪁 PageKite

**Komercyjny, niezawodny** - dobry dla biznesu.

### Rejestracja i konfiguracja

1. **Rejestracja**: https://pagekite.net/signup/
2. **Wybór planu** (od $3/miesiąc)
3. **Konfiguracja**:

```bash
TUNNEL_TYPE=pagekite
PAGEKITE_KITE=mybot.pagekite.me
PAGEKITE_SECRET=your_secret_key
```

### Instalacja i użycie

```bash
# Instalacja
curl -s https://pagekite.net/pk/ | sudo bash

# Konfiguracja
pagekite.py --signup

# Uruchomienie
pagekite.py 3000 mybot.pagekite.me
```

### Konfiguracja w kontenerze

```dockerfile
# docker/tunnel/pagekite/Dockerfile
FROM python:3.9-slim
RUN pip install pagekite
CMD pagekite.py --defaults 80 ${PAGEKITE_KITE}
```

### Zalety PageKite
- ✓ Bardzo stabilny
- ✓ Profesjonalne wsparcie
- ✓ Custom domeny
- ✓ Load balancing
- ✓ SSL certificates

### Wady PageKite
- ✗ Płatny (brak darmowego planu)
- ✗ Mniej popularny

## 🔧 Telebit

**Open source alternatywa** - dobra dla developerów.

### Instalacja

```bash
# Instalacja
curl https://get.telebit.io/ | bash

# Lub przez npm
npm install -g telebit
```

### Konfiguracja

```bash
TUNNEL_TYPE=telebit
TELEBIT_TOKEN=your_telebit_token  # opcjonalne
```

### Użycie

```bash
# Podstawowe użycie
telebit http 3000

# Z własną domeną
telebit http 3000 --servername mybot.telebit.io

# HTTPS
telebit http 3000 --https
```

### Zalety Telebit
- ✓ Open source
- ✓ Darmowy
- ✓ Obsługa custom domen
- ✓ Możliwość self-hostingu

### Wady Telebit
- ✗ Mniej stabilny
- ✗ Ograniczone wsparcie
- ✗ Mniejsza społeczność

## 🌐 Własna domena

**Najlepsze rozwiązanie produkcyjne** - pełna kontrola.

### Przygotowanie

1. **Serwer VPS** (DigitalOcean, Linode, AWS, itp.)
2. **Domena** (Namecheap, GoDaddy, Cloudflare, itp.)
3. **Konfiguracja DNS**

### Konfiguracja DNS

```bash
# Rekordy A (wskazują na IP serwera)
bot.yourdomain.com    A    your.server.ip.address
api.yourdomain.com    A    your.server.ip.address

# Rekord CNAME (alias)
www.bot.yourdomain.com    CNAME    bot.yourdomain.com
```

### Konfiguracja w .env

```bash
TUNNEL_TYPE=domain
DOMAIN_NAME=bot.yourdomain.com
SSL_ENABLED=true
```

### Nginx konfiguracja z SSL

```nginx
# docker/nginx/sites/bot.conf
server {
    listen 80;
    server_name bot.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name bot.yourdomain.com;
    
    ssl_certificate /etc/ssl/certs/bot.yourdomain.com.crt;
    ssl_certificate_key /etc/ssl/private/bot.yourdomain.com.key;
    
    location / {
        proxy_pass http://webui-frontend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api {
        proxy_pass http://webui-backend:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Automatyczny SSL z Let's Encrypt

```bash
# Instalacja certbot
sudo apt install certbot python3-certbot-nginx

# Pobranie certyfikatu
sudo certbot --nginx -d bot.yourdomain.com -d api.yourdomain.com

# Auto-renewal
sudo crontab -e
# Dodaj linię:
0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔒 Bezpieczeństwo tunelowania

### Środki bezpieczeństwa podstawowe

1. **Autoryzacja Web UI**

```python
# webui/backend/auth.py
from functools import wraps
from flask import request, jsonify

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get('Authorization')
        if not auth or not check_auth(auth):
            return jsonify({'error': 'Unauthorized'}), 401
        return f(*args, **kwargs)
    return decorated
```

2. **IP Whitelisting**

```bash
# W .env
FIREWALL_ENABLED=true
ALLOWED_IPS=127.0.0.1,::1,your.home.ip.address
```

3. **Rate Limiting**

```python
# webui/backend/rate_limit.py
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)
```

### HTTPS/SSL konfiguracja

```nginx
# docker/nginx/ssl.conf
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

# HSTS
add_header Strict-Transport-Security "max-age=31536000" always;

# CSP
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';";
```

### Monitoring i alerting

```bash
#!/bin/bash
# scripts/security_monitor.sh

# Monitorowanie nietypowego ruchu
tail -f /var/log/nginx/access.log | grep -E "(bot|crawler|scan)" | \
while read line; do
    echo "[ALERT] Suspicious activity: $line"
    # Wyślij email/Slack notification
done
```

### Backup i disaster recovery

```bash
#!/bin/bash
# scripts/backup.sh

# Backup bazy danych
docker-compose exec postgres pg_dump -U postgres trading_bot > backup_$(date +%Y%m%d).sql

# Backup konfiguracji
tar -czf config_backup_$(date +%Y%m%d).tar.gz .env lean/config/ models/

# Upload do cloud storage (opcjonalne)
# aws s3 cp backup_$(date +%Y%m%d).sql s3://your-backup-bucket/
```

## ⚡ Szybkie porady

### Wybór usługi tunelowania

- **Prototypy/testy**: LocalTunnel
- **Prezentacje/demo**: Ngrok
- **Produkcja z budżetem**: Własna domena + VPS
- **Enterprise**: Cloudflare Tunnel
- **Open source projekty**: Telebit

### Optymalizacja wydajności

```bash
# Kompresja w Nginx
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

# Caching
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Debugowanie problemów

```bash
# Test połączenia
curl -I http://your-tunnel-url.com

# Test SSL
openssl s_client -connect your-tunnel-url.com:443

# Test DNS
nslookup your-tunnel-url.com
dig your-tunnel-url.com

# Monitorowanie up-time
watch -n 30 "curl -s -o /dev/null -w '%{http_code}' http://your-tunnel-url.com"
```

---

**Następny krok**: [Konfiguracja brokerów](./BROKERS.md) lub [Bezpieczeństwo](./SECURITY.md)