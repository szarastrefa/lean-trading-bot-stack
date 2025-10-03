# 🏦 Przewodnik po konfigurowaniu brokerów

Kompletny przewodnik po konfigurowaniu połączeń z brokerami FX/CFD, krypto oraz MT4/MT5.

## 📝 Spis treści

1. [Wprowadzenie](#wprowadzenie)
2. [Brokerzy FX/CFD](#brokerzy-fxcfd)
3. [Brokerzy Krypto](#brokerzy-krypto)
4. [MT4/MT5 Bridge](#mt4mt5-bridge)
5. [Uniwersalny adapter](#uniwersalny-adapter)
6. [Testy i weryfikacja](#testy-i-weryfikacja)
7. [Bezpieczeństwo API](#bezpieczeństwo-api)

## 🎆 Wprowadzenie

**LEAN Trading Bot Stack** obsługuje szeroką gamę brokerów poprzez zunifikowane adaptery. Każdy broker wymaga konfiguracji kluczy API i specyficznych parametrów.

### Zalecane podejście

1. ⚠️ **Zawsze zaczynaj od kont demo/testnet**
2. 🔑 **Używaj kluczy z minimalnymi uprawnieniami**
3. 📊 **Testuj na małych kwotach**
4. 📝 **Monitoruj logi połączeń**
5. 🔄 **Regularnie rotuj klucze API**

## 💹 Brokerzy FX/CFD

### XM Group

**Popularny broker forex z dobrym API.**

#### Rejestracja API

1. Załóż konto na [XM.com](https://www.xm.com)
2. Przejdź do **Members Area** > **API**
3. Wygeneruj klucze API
4. Zanotuj **Account ID**

#### Konfiguracja

```bash
# W pliku .env
XM_API_KEY=your_xm_api_key
XM_API_SECRET=your_xm_api_secret
XM_ACCOUNT_ID=your_xm_account_id
XM_ENVIRONMENT=demo  # demo lub live
```

#### Przykład adaptera

```python
# lean/adapters/xm_adapter.py
class XMAdapter(BrokerAdapter):
    def __init__(self, config):
        self.api_key = config['XM_API_KEY']
        self.api_secret = config['XM_API_SECRET']
        self.account_id = config['XM_ACCOUNT_ID']
        self.environment = config['XM_ENVIRONMENT']
        self.base_url = 'https://api.xm.com' if self.environment == 'live' else 'https://api-demo.xm.com'
    
    def place_order(self, symbol, quantity, order_type, price=None):
        # Implementacja zleceń
        pass
    
    def get_account_info(self):
        # Pobranie informacji o koncie
        pass
```

### IC Markets

**Broker z doskonalym wykonaniem i niskimi spreadami.**

#### Rejestracja API

1. Załóż konto na [ICMarkets.com](https://www.icmarkets.com)
2. **Client Portal** > **Trading Tools** > **FIX API**
3. Pobierz dane dostępowe

#### Konfiguracja

```bash
# W pliku .env
IC_MARKETS_API_KEY=your_ic_markets_api_key
IC_MARKETS_API_SECRET=your_ic_markets_api_secret
IC_MARKETS_ACCOUNT_ID=your_ic_markets_account_id
IC_MARKETS_ENVIRONMENT=demo  # demo lub live
IC_MARKETS_FIX_HOST=fix-uat.icmarkets.com  # lub fix.icmarkets.com dla live
IC_MARKETS_FIX_PORT=8443
```

#### FIX API konfiguracja

```ini
# lean/config/ic_markets_fix.cfg
[DEFAULT]
ConnectionType=initiator
ReconnectInterval=60
SenderCompID=YOUR_SENDER_COMP_ID
TargetCompID=ICMARKETS
HeartBtInt=30
LogonTimeout=30

[SESSION]
BeginString=FIX.4.4
SocketConnectHost=fix-uat.icmarkets.com
SocketConnectPort=8443
Username=your_username
Password=your_password
EncryptMethod=0
```

### RoboForex

**Broker z wieloma typami kont i instrumentami.**

#### Konfiguracja

```bash
# W pliku .env
ROBOFOREX_API_KEY=your_roboforex_api_key
ROBOFOREX_API_SECRET=your_roboforex_api_secret
ROBOFOREX_ACCOUNT_ID=your_roboforex_account_id
ROBOFOREX_ENVIRONMENT=demo
ROBOFOREX_SERVER=RoboForex-Demo  # lub RoboForex-Live
```

### InstaForex

#### Konfiguracja

```bash
# W pliku .env
INSTAFOREX_API_KEY=your_instaforex_api_key
INSTAFOREX_API_SECRET=your_instaforex_api_secret
INSTAFOREX_ACCOUNT_ID=your_instaforex_account_id
INSTAFOREX_SERVER=InstaForex-Demo
```

### FBS

#### Konfiguracja

```bash
# W pliku .env
FBS_API_KEY=your_fbs_api_key
FBS_API_SECRET=your_fbs_api_secret
FBS_ACCOUNT_ID=your_fbs_account_id
FBS_SERVER=FBS-Demo
```

### XTB

**Broker z własnym API opartym na JSON.**

#### Rejestracja API

1. Załóż konto na [XTB.com](https://www.xtb.com)
2. **Office** > **Ustawienia** > **API**
3. Aktywuj dostęp do API

#### Konfiguracja

```bash
# W pliku .env
XTB_USER_ID=your_xtb_user_id
XTB_PASSWORD=your_xtb_password
XTB_ENVIRONMENT=demo  # demo lub real
```

#### Przykład połączenia

```python
# lean/adapters/xtb_adapter.py
import json
import websocket

class XTBAdapter(BrokerAdapter):
    def __init__(self, config):
        self.user_id = config['XTB_USER_ID']
        self.password = config['XTB_PASSWORD']
        self.environment = config['XTB_ENVIRONMENT']
        self.base_url = 'ws://xapi.xtb.com/demo' if self.environment == 'demo' else 'ws://xapi.xtb.com/real'
        self.session_id = None
    
    def login(self):
        ws = websocket.create_connection(self.base_url)
        login_command = {
            "command": "login",
            "arguments": {
                "userId": self.user_id,
                "password": self.password
            }
        }
        ws.send(json.dumps(login_command))
        response = json.loads(ws.recv())
        self.session_id = response['streamSessionId']
        return response['status']
```

### Admiral Markets

#### Konfiguracja

```bash
# W pliku .env
ADMIRAL_API_KEY=your_admiral_api_key
ADMIRAL_API_SECRET=your_admiral_api_secret
ADMIRAL_ACCOUNT_ID=your_admiral_account_id
ADMIRAL_ENVIRONMENT=demo
```

### IG Group

**Brytyjski broker z REST API.**

#### Konfiguracja

```bash
# W pliku .env
IG_API_KEY=your_ig_api_key
IG_USERNAME=your_ig_username
IG_PASSWORD=your_ig_password
IG_ENVIRONMENT=demo  # demo lub live
```

### Plus500

#### Konfiguracja

```bash
# W pliku .env
PLUS500_API_KEY=your_plus500_api_key
PLUS500_API_SECRET=your_plus500_api_secret
PLUS500_ENVIRONMENT=demo
```

### SabioTrade

**Specjalistyczny broker z zaawansowanym API.**

#### Konfiguracja

```bash
# W pliku .env
SABIOTRADE_API_KEY=your_sabiotrade_api_key
SABIOTRADE_API_SECRET=your_sabiotrade_api_secret
SABIOTRADE_ACCOUNT_ID=your_sabiotrade_account_id
SABIOTRADE_ENVIRONMENT=demo
```

## 🪙 Brokerzy Krypto

### Binance

**Największa giełda krypto na świecie.**

#### Rejestracja API

1. Załóż konto na [Binance.com](https://binance.com)
2. **API Management** > **Create API**
3. Ustaw uprawnienia: **Spot & Margin Trading**
4. Skonfiguruj IP whitelist (zalecane)

#### Konfiguracja

```bash
# W pliku .env
BINANCE_API_KEY=your_binance_api_key
BINANCE_API_SECRET=your_binance_api_secret
BINANCE_TESTNET=true  # Zawsze zaczynaj od testnet!
BINANCE_US=false      # true dla Binance US
```

#### Konfiguracja uprawnień API

- ✓ **Enable Reading** - do odczytu danych konta
- ✓ **Enable Spot & Margin Trading** - do handlu
- ✗ **Enable Withdrawals** - NIE włączaj (bezpieczeństwo)
- ✓ **Enable Futures** - opcjonalnie dla futures

#### Przykład użycia

```python
# lean/adapters/binance_adapter.py
from binance.client import Client
from binance.enums import *

class BinanceAdapter(BrokerAdapter):
    def __init__(self, config):
        self.client = Client(
            config['BINANCE_API_KEY'], 
            config['BINANCE_API_SECRET'],
            testnet=config.get('BINANCE_TESTNET', True)
        )
    
    def place_market_order(self, symbol, side, quantity):
        try:
            order = self.client.order_market(
                symbol=symbol,
                side=side,  # BUY or SELL
                quantity=quantity
            )
            return order
        except Exception as e:
            print(f"Error placing order: {e}")
            return None
```

### Coinbase Pro (Advanced Trade)

#### Rejestracja API

1. Załóż konto na [Coinbase.com](https://coinbase.com)
2. **Settings** > **API** > **New API Key**
3. Wybierz uprawnienia i wygeneruj klucze

#### Konfiguracja

```bash
# W pliku .env
COINBASE_API_KEY=your_coinbase_api_key
COINBASE_API_SECRET=your_coinbase_api_secret
COINBASE_PASSPHRASE=your_coinbase_passphrase
COINBASE_SANDBOX=true  # Sandbox dla testów
```

### Kraken

**Jedna z najstarszych i najbezpieczniejszych giełd.**

#### Rejestracja API

1. Załóż konto na [Kraken.com](https://kraken.com)
2. **Settings** > **API** > **Generate New Key**
3. Ustaw uprawnienia:
   - ✓ Query Funds
   - ✓ Query Open Orders & Trades
   - ✓ Query Closed Orders & Trades
   - ✓ Query Ledger Entries
   - ✓ Modify Orders
   - ✓ Cancel/Close Orders
   - ✗ Withdraw Funds (dla bezpieczeństwa)

#### Konfiguracja

```bash
# W pliku .env
KRAKEN_API_KEY=your_kraken_api_key
KRAKEN_API_SECRET=your_kraken_api_secret
```

#### Specjalne ustawienia Kraken

```bash
# Nonce window - ważne dla Kraken
KRAKEN_NONCE_WINDOW=5000
```

### Bitstamp

#### Konfiguracja

```bash
# W pliku .env
BITSTAMP_API_KEY=your_bitstamp_api_key
BITSTAMP_API_SECRET=your_bitstamp_api_secret
BITSTAMP_CUSTOMER_ID=your_bitstamp_customer_id
```

### Bitfinex

#### Konfiguracja

```bash
# W pliku .env
BITFINEX_API_KEY=your_bitfinex_api_key
BITFINEX_API_SECRET=your_bitfinex_api_secret
```

### Gemini

#### Konfiguracja

```bash
# W pliku .env
GEMINI_API_KEY=your_gemini_api_key
GEMINI_API_SECRET=your_gemini_api_secret
GEMINI_SANDBOX=true   # Sandbox dla testów
```

### Huobi

#### Konfiguracja

```bash
# W pliku .env
HUOBI_API_KEY=your_huobi_api_key
HUOBI_API_SECRET=your_huobi_api_secret
```

### OKX (OKEx)

#### Konfiguracja

```bash
# W pliku .env
OKX_API_KEY=your_okx_api_key
OKX_API_SECRET=your_okx_api_secret
OKX_PASSPHRASE=your_okx_passphrase
OKX_SANDBOX=true      # Sandbox dla testów
```

### Bybit

#### Konfiguracja

```bash
# W pliku .env
BYBIT_API_KEY=your_bybit_api_key
BYBIT_API_SECRET=your_bybit_api_secret
BYBIT_TESTNET=true    # Testnet dla testów
```

### KuCoin

#### Konfiguracja

```bash
# W pliku .env
KUCOIN_API_KEY=your_kucoin_api_key
KUCOIN_API_SECRET=your_kucoin_api_secret
KUCOIN_PASSPHRASE=your_kucoin_passphrase
KUCOIN_SANDBOX=true   # Sandbox dla testów
```

### Bittrex

#### Konfiguracja

```bash
# W pliku .env
BITTREX_API_KEY=your_bittrex_api_key
BITTREX_API_SECRET=your_bittrex_api_secret
```

## 🎯 MT4/MT5 Bridge

**Bridge umożliwia połączenie z terminalami MT4/MT5 i przekierowanie zleceń z LEAN.**

### Ogólna konfiguracja

```bash
# W pliku .env
MT_BRIDGE_ENABLED=true
MT_BRIDGE_TYPE=mt4     # mt4 lub mt5
MT_BRIDGE_HOST=localhost
MT_BRIDGE_PORT=8222
```

### XM MT4 Bridge

#### Konfiguracja terminala MT4

1. Pobierz i zainstaluj terminal MT4 od XM
2. Załoguj się na konto demo
3. Zainstaluj Expert Advisor "LEAN Bridge"

#### Konfiguracja w .env

```bash
# Szczegóły serwera MT4
XM_MT4_SERVER=XMGlobal-Demo
XM_MT4_LOGIN=your_mt4_login
XM_MT4_PASSWORD=your_mt4_password
```

#### Expert Advisor konfiguracja

```cpp
// lean/mt4_bridge/LEAN_Bridge.mq4
#property strict

extern string BridgeHost = "localhost";
extern int BridgePort = 8222;
extern int MagicNumber = 12345;

int OnInit() {
    // Inicjalizacja połączenia z LEAN
    return INIT_SUCCEEDED;
}

void OnTick() {
    // Obsługa ticków i synchronizacja z LEAN
}
```

### IC Markets MT4 Bridge

```bash
# Konfiguracja IC Markets MT4
IC_MT4_SERVER=ICMarkets-Demo01
IC_MT4_LOGIN=your_ic_mt4_login
IC_MT4_PASSWORD=your_ic_mt4_password
```

### Bridge Server

```python
# lean/mt4_bridge/bridge_server.py
import socket
import json
from threading import Thread

class MT4BridgeServer:
    def __init__(self, host='localhost', port=8222):
        self.host = host
        self.port = port
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
    def start(self):
        self.socket.bind((self.host, self.port))
        self.socket.listen(5)
        print(f"MT4 Bridge Server listening on {self.host}:{self.port}")
        
        while True:
            client, address = self.socket.accept()
            Thread(target=self.handle_client, args=(client,)).start()
    
    def handle_client(self, client_socket):
        while True:
            try:
                data = client_socket.recv(1024).decode('utf-8')
                if data:
                    command = json.loads(data)
                    response = self.process_command(command)
                    client_socket.send(json.dumps(response).encode('utf-8'))
            except:
                break
        client_socket.close()
    
    def process_command(self, command):
        # Przetwarzanie komend z MT4/MT5
        if command['action'] == 'place_order':
            return self.place_order(command)
        elif command['action'] == 'get_account_info':
            return self.get_account_info()
        else:
            return {'status': 'error', 'message': 'Unknown command'}
```

## 🔧 Uniwersalny adapter

**Adapter dla brokerów nie obsługiwanych bezpośrednio.**

### Konfiguracja custom adaptera

```python
# lean/adapters/universal_adapter.py
class UniversalAdapter(BrokerAdapter):
    def __init__(self, config):
        self.broker_name = config.get('UNIVERSAL_BROKER_NAME', 'Custom')
        self.api_url = config.get('UNIVERSAL_API_URL')
        self.api_key = config.get('UNIVERSAL_API_KEY')
        self.api_secret = config.get('UNIVERSAL_API_SECRET')
        
    def place_order(self, symbol, quantity, order_type, price=None):
        # Implementacja generyczna oparta na REST API
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }
        
        payload = {
            'symbol': symbol,
            'quantity': quantity,
            'type': order_type,
            'price': price
        }
        
        response = requests.post(
            f'{self.api_url}/orders',
            headers=headers,
            json=payload
        )
        
        return response.json()
```

### Konfiguracja w .env

```bash
# Universal Adapter
UNIVERSAL_BROKER_NAME=MyBroker
UNIVERSAL_API_URL=https://api.mybroker.com/v1
UNIVERSAL_API_KEY=your_universal_api_key
UNIVERSAL_API_SECRET=your_universal_api_secret
```

## ✅ Testy i weryfikacja

### Test połączeń z brokerami

```python
# scripts/test_brokers.py
import os
from lean.adapters import *

def test_broker_connection(broker_name, adapter_class):
    try:
        config = {
            f'{broker_name.upper()}_API_KEY': os.getenv(f'{broker_name.upper()}_API_KEY'),
            f'{broker_name.upper()}_API_SECRET': os.getenv(f'{broker_name.upper()}_API_SECRET'),
        }
        
        adapter = adapter_class(config)
        account_info = adapter.get_account_info()
        
        if account_info:
            print(f"✓ {broker_name}: Połączenie udane")
            print(f"  Saldo: {account_info.get('balance', 'N/A')}")
            return True
        else:
            print(f"✗ {broker_name}: Brak danych konta")
            return False
            
    except Exception as e:
        print(f"✗ {broker_name}: Błąd połączenia - {e}")
        return False

if __name__ == '__main__':
    brokers = [
        ('Binance', BinanceAdapter),
        ('Kraken', KrakenAdapter),
        ('XM', XMAdapter),
        ('IC_Markets', ICMarketsAdapter),
    ]
    
    print("=== TEST POŁĄCZEŃ Z BROKERAMI ===")
    for broker_name, adapter_class in brokers:
        test_broker_connection(broker_name, adapter_class)
```

### Uruchomienie testów

```bash
# Test wszystkich brokerów
python scripts/test_brokers.py

# Test konkretnego brokera
python scripts/test_single_broker.py binance

# Test z kontenerem Docker
docker-compose exec webui-backend python scripts/test_brokers.py
```

### Monitoring połączeń

```python
# scripts/monitor_brokers.py
import time
import json
from datetime import datetime

def monitor_broker_health():
    brokers_status = {}
    
    for broker in ['binance', 'kraken', 'xm']:
        try:
            # Test połączenia
            adapter = get_adapter(broker)
            account_info = adapter.get_account_info()
            
            brokers_status[broker] = {
                'status': 'online',
                'last_check': datetime.now().isoformat(),
                'balance': account_info.get('balance', 0)
            }
        except Exception as e:
            brokers_status[broker] = {
                'status': 'offline',
                'last_check': datetime.now().isoformat(),
                'error': str(e)
            }
    
    # Zapis do pliku
    with open('logs/brokers_status.json', 'w') as f:
        json.dump(brokers_status, f, indent=2)
    
    return brokers_status

if __name__ == '__main__':
    while True:
        status = monitor_broker_health()
        print(f"Broker health check: {datetime.now()}")
        for broker, info in status.items():
            print(f"  {broker}: {info['status']}")
        time.sleep(300)  # Co 5 minut
```

## 🔐 Bezpieczeństwo API

### Najlepsze praktyki

1. **🔑 Minimalne uprawnienia**
   - Tylko odczyt + trading
   - Bez uprawnień do wypłat
   - IP whitelisting

2. **🔄 Rotacja kluczy**
   ```bash
   # Automatyczna rotacja co 30 dni
   0 0 1 * * /opt/trading-bot/scripts/rotate_api_keys.sh
   ```

3. **📊 Monitoring**
   ```python
   # Alerting o nietypowej aktywności
   def check_unusual_activity():
       # Sprawdź nietypowo duże zlecenia
       # Sprawdź połączenia z nowych IP
       # Sprawdź frequency zleceń
       pass
   ```

4. **🛡️ Rate limiting**
   ```python
   # Ograniczenie zapytań API
   from ratelimit import limits, sleep_and_retry
   
   @sleep_and_retry
   @limits(calls=10, period=60)  # 10 calls per minute
   def api_call():
       # API request
       pass
   ```

### Szyfrowanie kluczy API

```python
# utils/encryption.py
from cryptography.fernet import Fernet
import os

class APIKeyManager:
    def __init__(self):
        key = os.getenv('ENCRYPTION_KEY')
        if not key:
            key = Fernet.generate_key()
            print(f"Generated new encryption key: {key.decode()}")
        self.cipher = Fernet(key)
    
    def encrypt_key(self, api_key):
        return self.cipher.encrypt(api_key.encode()).decode()
    
    def decrypt_key(self, encrypted_key):
        return self.cipher.decrypt(encrypted_key.encode()).decode()
```

### Backup konfiguracji

```bash
#!/bin/bash
# scripts/backup_broker_config.sh

# Backup konfiguracji (bez kluczy API)
cp .env.example backup/.env.backup.$(date +%Y%m%d)

# Backup adapterów
tar -czf backup/adapters_backup_$(date +%Y%m%d).tar.gz lean/adapters/

# Backup konfiguracji LEAN
tar -czf backup/lean_config_$(date +%Y%m%d).tar.gz lean/config/

echo "Backup zakończony: $(date)"
```

## 🚑 Wsparcie i debugging

### Logi brokerów

```bash
# Logi połączeń z brokerami
docker-compose logs webui-backend | grep -i broker

# Logi konkretnego brokera
docker-compose logs webui-backend | grep -i binance

# Logi błędów API
docker-compose logs webui-backend | grep -i "api error"
```

### Debug mode

```python
# lean/adapters/base_adapter.py
import logging

class BrokerAdapter:
    def __init__(self, config):
        self.debug = config.get('DEBUG_MODE', False)
        if self.debug:
            logging.basicConfig(level=logging.DEBUG)
            
    def log_api_call(self, method, url, params=None):
        if self.debug:
            logging.debug(f"API Call: {method} {url}")
            if params:
                logging.debug(f"Params: {params}")
```

### Częste problemy

| Problem | Rozwiązanie |
|---------|---------------|
| "Invalid API key" | Sprawdź klucze w .env, regeneruj jeśli potrzeba |
| "Insufficient permissions" | Sprawdź uprawnienia API key na stronie brokera |
| "Rate limit exceeded" | Zmniejsz częstotliwość zapytań, dodaj opóźnienia |
| "Connection timeout" | Sprawdź połączenie internetowe, firewall |
| "Invalid nonce" | (Kraken) Zwiększ NONCE_WINDOW w konfiguracji |

---

**Następny krok**: [Bezpieczeństwo](./SECURITY.md) lub wróć do [Instalacji](./INSTALL.md)