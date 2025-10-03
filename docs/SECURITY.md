# 🔒 Bezpieczeństwo i Production Hardening

Kompletny przewodnik po zabezpieczeniu LEAN Trading Bot Stack dla środowiska produkcyjnego.

## 📝 Spis treści

1. [Ogólne zasady bezpieczeństwa](#ogólne-zasady-bezpieczeństwa)
2. [Konfiguracja Docker](#konfiguracja-docker)
3. [Sieciowanie i TLS](#sieciowanie-i-tls)
4. [Zarządzanie sekretami](#zarządzanie-sekretami)
5. [Monitoring i audyt](#monitoring-i-audyt)
6. [Backup i disaster recovery](#backup-i-disaster-recovery)
7. [Compliance i regulacje](#compliance-i-regulacje)
8. [Checklist produkcyjny](#checklist-produkcyjny)

## 🛡️ Ogólne zasady bezpieczeństwa

### Defense in Depth

**Wielowarstwowe zabezpieczenia** - każda warstwa powinna być niezależna.

```
┌─────────────────────────────────────────────────────────────────────┐
│ WARSTWA 7: Aplikacja (Rate Limiting, Input Validation)           │
├─────────────────────────────────────────────────────────────────────┤
│ WARSTWA 6: TLS/SSL (Szyfrowanie komunikacji)                   │
├─────────────────────────────────────────────────────────────────────┤
│ WARSTWA 5: Reverse Proxy (Nginx, Load Balancing)               │
├─────────────────────────────────────────────────────────────────────┤
│ WARSTWA 4: Konteneryzacja (Docker Security)                    │
├─────────────────────────────────────────────────────────────────────┤
│ WARSTWA 3: Sieciowanie (Firewall, VPN, Network Segmentation)   │
├─────────────────────────────────────────────────────────────────────┤
│ WARSTWA 2: OS (System Hardening, User Management)              │
├─────────────────────────────────────────────────────────────────────┤
│ WARSTWA 1: Fizyczna (Data Center, Access Control)              │
└─────────────────────────────────────────────────────────────────────┘
```

### Podstawowe zasady

1. **🔐 Principle of Least Privilege** - minimalne niezbędne uprawnienia
2. **🔄 Defense in Depth** - wielowarstwowe zabezpieczenia
3. **📊 Fail Securely** - bezpieczne zachowanie w przypadku błędu
4. **🔍 Zero Trust** - weryfikuj wszystko, nikomu nie ufaj
5. **📝 Audit Everything** - loguj wszystkie działania

## 🐳 Konfiguracja Docker

### Hardening kontenerów

#### Nie uruchamiaj jako root

```dockerfile
# docker/webui/Dockerfile
FROM python:3.11-slim

# Utworzenie użytkownika bez uprawnień
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Instalacja zależności jako root
COPY requirements.txt .
RUN pip install -r requirements.txt

# Przejście na użytkownika bez uprawnień
USER appuser

# Reszta konfiguracji
WORKDIR /app
COPY --chown=appuser:appuser . .

EXPOSE 5000
CMD ["python", "app.py"]
```

#### Ograniczenie zasobów

```yaml
# docker-compose.override.yml dla produkcji
version: '3.8'

services:
  webui-backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Tylko jeśli potrzebne
```

#### Security scan kontenerów

```bash
#!/bin/bash
# scripts/security_scan.sh

# Instalacja Trivy (vulnerability scanner)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan wszystkich obrazów
echo "=== SKANOWANIE BEZPIECZEŃSTWA OBRAZÓW DOCKER ==="
for image in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>"); do
    echo "Skanowanie: $image"
    trivy image --severity HIGH,CRITICAL $image
done

# Scan systemu plików
echo "=== SKANOWANIE SYSTEMU PLIKÓW ==="
trivy fs --severity HIGH,CRITICAL .
```

### Docker daemon security

```json
# /etc/docker/daemon.json
{
  "icc": false,
  "userland-proxy": false,
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp.json",
  "apparmor-profile": "docker-default",
  "selinux-enabled": true,
  "disable-legacy-registry": true,
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
```

## 🌐 Sieciowanie i TLS

### TLS/SSL konfiguracja

#### Nginx z mocnym TLS

```nginx
# docker/nginx/conf.d/ssl.conf
server {
    listen 443 ssl http2;
    server_name bot.yourdomain.com;
    
    # SSL Certificate
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.3 TLSv1.2;
    ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;
    
    # SSL session caching
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/nginx/ssl/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self' wss: ws:;" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    
    location / {
        proxy_pass http://webui-frontend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://webui-backend:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api/auth/login {
        limit_req zone=login burst=5 nodelay;
        
        proxy_pass http://webui-backend:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name bot.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

#### Automatyczne odnowienie SSL (Let's Encrypt)

```bash
#!/bin/bash
# scripts/renew_ssl.sh

set -e

DOMAIN="bot.yourdomain.com"
WEBROOT="/var/www/html"
CERT_DIR="/etc/nginx/ssl"

# Sprawdzenie ważności certyfikatu
if openssl x509 -checkend 2592000 -noout -in "$CERT_DIR/fullchain.pem" > /dev/null 2>&1; then
    echo "Certyfikat jest ważny przez kolejne 30 dni"
    exit 0
fi

echo "Odnowienie certyfikatu SSL..."

# Zatrzymanie nginx
docker-compose stop nginx

# Odnowienie certyfikatu
certbot certonly \
    --standalone \
    --email admin@yourdomain.com \
    --agree-tos \
    --no-eff-email \
    --domains $DOMAIN \
    --cert-path $CERT_DIR/cert.pem \
    --chain-path $CERT_DIR/chain.pem \
    --fullchain-path $CERT_DIR/fullchain.pem \
    --key-path $CERT_DIR/privkey.pem

# Uruchomienie nginx
docker-compose start nginx

echo "Certyfikat odnowiony pomyślnie"

# Test konfiguracji
nginx -t && systemctl reload nginx
```

### Firewall i segmentacja sieci

#### UFW (Ubuntu Firewall)

```bash
#!/bin/bash
# scripts/setup_firewall.sh

# Reset UFW
sudo ufw --force reset

# Domyślne zasady
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH (zmień port jeśli inny)
sudo ufw allow 22/tcp comment 'SSH'

# HTTP/HTTPS
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Docker (jeśli potrzebne zdalne połączenie)
# sudo ufw allow 2376/tcp comment 'Docker TLS'

# Pozwól na komunikację wewnątrz sieci Docker
sudo ufw allow from 172.20.0.0/16

# Specyficzne IP (jeśli znane)
# sudo ufw allow from YOUR_HOME_IP comment 'Home IP'

# Włączenie UFW
sudo ufw --force enable

# Status
sudo ufw status verbose
```

#### Docker network isolation

```yaml
# docker-compose.override.yml
version: '3.8'

networks:
  frontend:
    driver: bridge
    internal: false  # Połączenie z internetem
  backend:
    driver: bridge
    internal: true   # Bez połączenia z internetem
  database:
    driver: bridge
    internal: true   # Izolowana sieć dla bazy

services:
  nginx:
    networks:
      - frontend
      
  webui-frontend:
    networks:
      - frontend
      - backend
      
  webui-backend:
    networks:
      - backend
      - database
      
  postgres:
    networks:
      - database
      
  redis:
    networks:
      - database
```

## 🔑 Zarządzanie sekretami

### Docker Secrets

```bash
# Tworzenie secretów Docker Swarm
echo "super_secure_postgres_password" | docker secret create postgres_password -
echo "redis_password_123" | docker secret create redis_password -
echo "flask_secret_key_xyz" | docker secret create flask_secret_key -
```

```yaml
# docker-compose.secrets.yml
version: '3.8'

secrets:
  postgres_password:
    external: true
  redis_password:
    external: true
  flask_secret_key:
    external: true

services:
  postgres:
    secrets:
      - postgres_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
      
  webui-backend:
    secrets:
      - flask_secret_key
    environment:
      FLASK_SECRET_KEY_FILE: /run/secrets/flask_secret_key
```

### HashiCorp Vault integration

```python
# utils/vault_client.py
import hvac
import os

class VaultClient:
    def __init__(self):
        self.client = hvac.Client(
            url=os.getenv('VAULT_URL', 'http://localhost:8200'),
            token=os.getenv('VAULT_TOKEN')
        )
        
    def get_secret(self, path):
        """Pobranie sekretu z Vault"""
        try:
            response = self.client.secrets.kv.v2.read_secret_version(path=path)
            return response['data']['data']
        except Exception as e:
            print(f"Error reading secret {path}: {e}")
            return None
    
    def put_secret(self, path, secret):
        """Zapisanie sekretu do Vault"""
        try:
            self.client.secrets.kv.v2.create_or_update_secret(
                path=path,
                secret=secret
            )
            return True
        except Exception as e:
            print(f"Error writing secret {path}: {e}")
            return False

# Przykład użycia
vault = VaultClient()
api_keys = vault.get_secret('trading-bot/api-keys')
if api_keys:
    binance_key = api_keys.get('binance_api_key')
```

### Szyfrowanie danych w spoczynku

```python
# utils/encryption.py
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import os
import base64

class DataEncryption:
    def __init__(self, password=None):
        if not password:
            password = os.getenv('ENCRYPTION_PASSWORD', 'default-password')
        
        # Derive key from password
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=b'stable_salt_for_trading_bot',  # W produkcji użyj losowej soli
            iterations=100000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        self.cipher = Fernet(key)
    
    def encrypt(self, data):
        """Szyfrowanie danych"""
        if isinstance(data, str):
            data = data.encode()
        return self.cipher.encrypt(data)
    
    def decrypt(self, encrypted_data):
        """Deszyfrowanie danych"""
        decrypted = self.cipher.decrypt(encrypted_data)
        return decrypted.decode()

# Przykład użycia
encryptor = DataEncryption()
encrypted_api_key = encryptor.encrypt("your_api_key")
stored_key = encryptor.decrypt(encrypted_api_key)
```

## 📊 Monitoring i audyt

### Centralized logging (ELK Stack)

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - monitoring
      
  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    volumes:
      - ./monitoring/logstash/pipeline:/usr/share/logstash/pipeline
    networks:
      - monitoring
    depends_on:
      - elasticsearch
      
  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    networks:
      - monitoring
    depends_on:
      - elasticsearch
      
  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    user: root
    volumes:
      - ./monitoring/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - monitoring
    depends_on:
      - elasticsearch

volumes:
  elasticsearch_data:

networks:
  monitoring:
    driver: bridge
```

### Security monitoring

```python
# monitoring/security_monitor.py
import re
import time
import json
from datetime import datetime
from collections import defaultdict

class SecurityMonitor:
    def __init__(self):
        self.failed_logins = defaultdict(int)
        self.suspicious_ips = set()
        self.api_abuse = defaultdict(int)
        
    def analyze_log_line(self, log_line):
        """Analiza linii loga pod kątem zagrożeń"""
        alerts = []
        
        # Wykrywanie prób łamania haseł
        if "failed login" in log_line.lower():
            ip = self.extract_ip(log_line)
            if ip:
                self.failed_logins[ip] += 1
                if self.failed_logins[ip] > 5:
                    alerts.append({
                        'type': 'brute_force',
                        'ip': ip,
                        'count': self.failed_logins[ip],
                        'timestamp': datetime.now().isoformat()
                    })
        
        # Wykrywanie nadmiernego użycia API
        if "api_call" in log_line:
            ip = self.extract_ip(log_line)
            if ip:
                self.api_abuse[ip] += 1
                if self.api_abuse[ip] > 1000:  # 1000 zapytań na minutę
                    alerts.append({
                        'type': 'api_abuse',
                        'ip': ip,
                        'count': self.api_abuse[ip],
                        'timestamp': datetime.now().isoformat()
                    })
        
        # Wykrywanie nietypowych wzorców
        suspicious_patterns = [
            r'\.\./',  # Directory traversal
            r'<script',  # XSS attempts
            r'union.*select',  # SQL injection
            r'eval\(',  # Code injection
        ]
        
        for pattern in suspicious_patterns:
            if re.search(pattern, log_line, re.IGNORECASE):
                alerts.append({
                    'type': 'suspicious_pattern',
                    'pattern': pattern,
                    'log_line': log_line,
                    'timestamp': datetime.now().isoformat()
                })
        
        return alerts
    
    def extract_ip(self, log_line):
        """Wyodrębnienie IP z linii loga"""
        ip_pattern = r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
        match = re.search(ip_pattern, log_line)
        return match.group(1) if match else None
    
    def send_alert(self, alert):
        """Wysłanie alertu"""
        # Integracja z Slack, email, webhook, itp.
        print(f"ALERT: {json.dumps(alert, indent=2)}")
        
        # Można dodać integracje:
        # - Slack webhook
        # - Email
        # - PagerDuty
        # - Custom webhook
```

### Intrusion Detection System (IDS)

```bash
#!/bin/bash
# monitoring/ids_monitor.sh

# Monitor nietypowego ruchu sieciowego
netstat -an | grep :443 | wc -l > /tmp/https_connections
HTTPS_CONN=$(cat /tmp/https_connections)

if [ $HTTPS_CONN -gt 1000 ]; then
    echo "ALERT: Nietypowo dużo połączeń HTTPS: $HTTPS_CONN" | \
    logger -t IDS -p local0.warning
fi

# Monitor CPU i pamięci
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEM_USAGE=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')

if (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
    echo "ALERT: Wysokie zużycie CPU: $CPU_USAGE%" | \
    logger -t IDS -p local0.warning
fi

if (( $(echo "$MEM_USAGE > 90" | bc -l) )); then
    echo "ALERT: Wysokie zużycie pamięci: $MEM_USAGE%" | \
    logger -t IDS -p local0.warning
fi

# Monitor nieprawidłowych loginów
FAILED_LOGINS=$(journalctl --since "1 minute ago" | grep "Failed password" | wc -l)
if [ $FAILED_LOGINS -gt 5 ]; then
    echo "ALERT: Nietypowa liczba nieudanych loginów: $FAILED_LOGINS" | \
    logger -t IDS -p local0.error
fi
```

## 📋 Backup i disaster recovery

### Automated backup strategy

```bash
#!/bin/bash
# scripts/backup_system.sh

set -e

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="your-backup-bucket"
RETENTION_DAYS=30

echo "Rozpoczynanie backup systemu: $DATE"

# 1. Backup bazy danych
echo "Backup bazy danych..."
docker-compose exec -T postgres pg_dump -U postgres trading_bot | \
gzip > "$BACKUP_DIR/database_$DATE.sql.gz"

# 2. Backup Redis
echo "Backup Redis..."
docker-compose exec -T redis redis-cli BGSAVE
sleep 10
docker cp redis-cache:/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

# 3. Backup konfiguracji (bez sekretów)
echo "Backup konfiguracji..."
tar --exclude='.env' --exclude='*.log' --exclude='node_modules' \
    -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
    docker-compose.yml lean/ webui/ models/ docs/

# 4. Backup modeli ML
echo "Backup modeli ML..."
tar -czf "$BACKUP_DIR/models_$DATE.tar.gz" models/

# 5. Upload do cloud storage (opcjonalne)
if [ -n "$S3_BUCKET" ]; then
    echo "Upload do S3..."
    aws s3 sync "$BACKUP_DIR/" "s3://$S3_BUCKET/trading-bot-backups/"
fi

# 6. Usuwanie starych backupów
echo "Usuwanie starych backupów..."
find "$BACKUP_DIR" -name "*" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup zakończony: $DATE"

# 7. Weryfikacja integralności
echo "Weryfikacja backupów..."
for file in "$BACKUP_DIR"/*"$DATE"*; do
    if [ -f "$file" ]; then
        echo "Sprawdzanie: $file"
        if [[ $file == *.gz ]]; then
            gzip -t "$file" && echo "  OK" || echo "  DAMAGED"
        elif [[ $file == *.tar.gz ]]; then
            tar -tzf "$file" > /dev/null && echo "  OK" || echo "  DAMAGED"
        fi
    fi
done
```

### Disaster Recovery Plan

```bash
#!/bin/bash
# scripts/disaster_recovery.sh

set -e

BACKUP_FILE="$1"
RECOVERY_DATE=$(date +%Y%m%d_%H%M%S)

if [ -z "$BACKUP_FILE" ]; then
    echo "Użycie: $0 <backup_file_date>"
    echo "Przykład: $0 20241203_140000"
    exit 1
fi

echo "=== DISASTER RECOVERY START ==="
echo "Data recovery: $RECOVERY_DATE"
echo "Backup file: $BACKUP_FILE"
echo "====================================="

# 1. Zatrzymanie usług
echo "Zatrzymywanie usług..."
docker-compose down

# 2. Backup aktualnych danych (na wszelki wypadek)
echo "Backup aktualnych danych..."
mkdir -p "/opt/recovery_backup_$RECOVERY_DATE"
docker run --rm -v postgres_data:/data -v "/opt/recovery_backup_$RECOVERY_DATE":/backup alpine \
    tar czf /backup/postgres_current.tar.gz -C /data .

# 3. Przywracanie bazy danych
echo "Przywracanie bazy danych..."
docker-compose up -d postgres
sleep 10

gunzip -c "/opt/backups/database_$BACKUP_FILE.sql.gz" | \
docker-compose exec -T postgres psql -U postgres -d trading_bot

# 4. Przywracanie Redis
echo "Przywracanie Redis..."
docker-compose up -d redis
sleep 5
docker cp "/opt/backups/redis_$BACKUP_FILE.rdb" redis-cache:/data/dump.rdb
docker-compose restart redis

# 5. Przywracanie konfiguracji
echo "Przywracanie konfiguracji..."
tar -xzf "/opt/backups/config_$BACKUP_FILE.tar.gz" -C /tmp/
# Ostrzeżenie: nie nadpisujemy .env - może zawierać nowe klucze
echo "UWAGA: Sprawdź ręcznie konfiguracje w /tmp/"

# 6. Przywracanie modeli ML
echo "Przywracanie modeli ML..."
tar -xzf "/opt/backups/models_$BACKUP_FILE.tar.gz" -C .

# 7. Uruchomienie usług
echo "Uruchamianie usług..."
docker-compose up -d

echo "=== DISASTER RECOVERY COMPLETE ==="
echo "Sprawdź:"
echo "1. docker-compose ps"
echo "2. Logi: docker-compose logs"
echo "3. Test połączenia: curl http://localhost:3000"
echo "4. Sprawdź dane w WebUI"
```

## 📜 Compliance i regulacje

### GDPR Compliance

```python
# utils/gdpr_compliance.py
from datetime import datetime, timedelta
import json

class GDPRManager:
    def __init__(self, db_connection):
        self.db = db_connection
        
    def log_data_access(self, user_id, data_type, purpose):
        """Logowanie dostępu do danych osobowych"""
        self.db.execute("""
            INSERT INTO data_access_log (user_id, data_type, purpose, timestamp)
            VALUES (?, ?, ?, ?)
        """, (user_id, data_type, purpose, datetime.now()))
    
    def anonymize_user_data(self, user_id):
        """Anonimizacja danych użytkownika"""
        # Zachowaj tylko niezbędne dane dla audytu
        self.db.execute("""
            UPDATE users SET 
                email = 'anonymized@example.com',
                name = 'Anonymized User',
                phone = NULL,
                address = NULL
            WHERE id = ?
        """, (user_id,))
        
        # Loguj anonimizację
        self.log_data_access(user_id, 'user_profile', 'anonymization')
    
    def export_user_data(self, user_id):
        """Eksport wszystkich danych użytkownika"""
        user_data = {
            'profile': self.get_user_profile(user_id),
            'trading_history': self.get_trading_history(user_id),
            'api_usage': self.get_api_usage(user_id),
            'logs': self.get_user_logs(user_id)
        }
        
        self.log_data_access(user_id, 'full_export', 'data_portability')
        return json.dumps(user_data, indent=2)
```

### Audit Trail

```python
# utils/audit_trail.py
import json
from datetime import datetime
from functools import wraps

def audit_action(action_type):
    """Dekorator do audytu akcji"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = datetime.now()
            
            try:
                result = func(*args, **kwargs)
                
                # Loguj sukces
                log_audit_event({
                    'action_type': action_type,
                    'function': func.__name__,
                    'args': str(args)[:200],  # Limit długości
                    'kwargs': str(kwargs)[:200],
                    'status': 'success',
                    'timestamp': start_time.isoformat(),
                    'duration_ms': (datetime.now() - start_time).total_seconds() * 1000
                })
                
                return result
                
            except Exception as e:
                # Loguj błąd
                log_audit_event({
                    'action_type': action_type,
                    'function': func.__name__,
                    'args': str(args)[:200],
                    'kwargs': str(kwargs)[:200],
                    'status': 'error',
                    'error': str(e),
                    'timestamp': start_time.isoformat(),
                    'duration_ms': (datetime.now() - start_time).total_seconds() * 1000
                })
                raise
                
        return wrapper
    return decorator

def log_audit_event(event):
    """Zapisanie zdarzenia audytu"""
    # Zapisz do bazy danych lub systemu logów
    with open('/var/log/trading-bot/audit.log', 'a') as f:
        f.write(json.dumps(event) + '\n')

# Przykład użycia
@audit_action('place_order')
def place_order(symbol, quantity, price):
    # Implementacja zlecenia
    pass

@audit_action('withdraw_funds')
def withdraw_funds(amount, destination):
    # Implementacja wypłaty
    pass
```

## ✅ Checklist produkcyjny

### Pre-production security checklist

```markdown
## 🔒 SECURITY CHECKLIST PRODUKCYJNY

### 🐳 Docker Security
- [ ] Wszystkie kontenery uruchamiane jako non-root
- [ ] Zasoby kontenerów są ograniczone (CPU, RAM)
- [ ] Użyte `--read-only` gdzie to możliwe
- [ ] Usunięte wszystkie niepotrzebne capabilities
- [ ] Skanowanie obrazów na vulnerabilities (Trivy)
- [ ] Aktualne wersje wszystkich obrazów bazowych

### 🌐 Network Security
- [ ] TLS 1.3 skonfigurowany poprawnie
- [ ] Mocne cipher suites
- [ ] HSTS headers włączone
- [ ] CSP headers skonfigurowane
- [ ] Rate limiting włączony
- [ ] Firewall skonfigurowany (tylko niezbędne porty)
- [ ] Network segmentation (izolacja baz danych)

### 🔑 Secrets Management
- [ ] Żaden sekret w kodzie źródłowym
- [ ] Plik .env NIE jest w repozytorium
- [ ] Sekrety szyfrowane w spoczynku
- [ ] API keys mają minimalne uprawnienia
- [ ] Regularna rotacja kluczy

### 📊 Monitoring & Logging
- [ ] Centralized logging skonfigurowany
- [ ] Security monitoring włączony
- [ ] Alerting dla nietypowej aktywności
- [ ] Audit trail wszystkich akcji
- [ ] Log retention policy zdefiniowana

### 📋 Backup & Recovery
- [ ] Automatyczne backup skonfigurowane
- [ ] Backup testowane regularnie
- [ ] Disaster recovery plan przetestowany
- [ ] RTO/RPO zdefiniowane i osiągalne
- [ ] Off-site backup włączony

### 📜 Compliance
- [ ] GDPR compliance (jeśli dotyczy)
- [ ] Audit trail kompletny
- [ ] Data retention policy
- [ ] Privacy policy aktualna
- [ ] Terms of service aktualne

### 🔧 Application Security
- [ ] Input validation na wszystkich endpointów
- [ ] SQL injection protection
- [ ] XSS protection
- [ ] CSRF protection
- [ ] Authentication i authorization
- [ ] Session management bezpieczny

### 🚫 Final Checks
- [ ] Wszystkie domyślne hasła zmienione
- [ ] Debug mode wyłączony w produkcji
- [ ] Niepotrzebne porty zamknięte
- [ ] Test environment odłączony od produkcji
- [ ] Security scan przeprowadzony
- [ ] Penetration testing wykonany
```

### Automated security testing

```bash
#!/bin/bash
# scripts/security_test.sh

echo "=== AUTOMATED SECURITY TESTING ==="

# 1. Docker security scan
echo "[1/6] Docker security scan..."
trivy image --severity HIGH,CRITICAL lean-trading-bot-stack_webui-backend
trivy image --severity HIGH,CRITICAL lean-trading-bot-stack_webui-frontend

# 2. SSL/TLS test
echo "[2/6] SSL/TLS test..."
if command -v testssl.sh &> /dev/null; then
    testssl.sh --quiet --color 0 https://bot.yourdomain.com
else
    echo "testssl.sh not found, skipping SSL test"
fi

# 3. Port scan
echo "[3/6] Port scan..."
nmap -sS -O localhost

# 4. Web application security
echo "[4/6] Web application security test..."
if command -v nikto &> /dev/null; then
    nikto -h http://localhost:3000 -o /tmp/nikto_report.txt
    echo "Nikto report saved to /tmp/nikto_report.txt"
else
    echo "Nikto not found, skipping web app security test"
fi

# 5. Configuration audit
echo "[5/6] Configuration audit..."
docker run --rm -v "$PWD":/tmp/audit \
    securecodewarrior/docker-bench-security

# 6. Dependency check
echo "[6/6] Dependency vulnerability check..."
if [ -f "webui/backend/requirements.txt" ]; then
    safety check -r webui/backend/requirements.txt
fi

if [ -f "webui/frontend/package.json" ]; then
    cd webui/frontend && npm audit
fi

echo "=== SECURITY TESTING COMPLETE ==="
```

---

**Pamiętaj**: Bezpieczeństwo to proces ciągły, nie jednorazowe zadanie. Regularnie aktualizuj systemy, monitoruj logi i testuj zabezpieczenia.

**Następne kroki**: Przeczytaj [INSTALL.md](./INSTALL.md) aby rozpocząć bezpieczną instalację.