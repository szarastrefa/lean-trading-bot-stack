# LEAN Trading Bot Stack

🚀 **Kompletny projekt bota tradingowego oparty na QuantConnect LEAN z Web UI, integracją ML/AI oraz obsługą wielu brokerów**

## 🌟 Funkcje

- ⚡ **QuantConnect LEAN Engine** - Profesjonalny silnik backtestingu i live tradingu
- 🌐 **Responsywne Web UI** - Konfigurator strategii, zarządzanie brokerami, monitorowanie
- 🤖 **Integracja AI/ML** - Import/eksport modeli ONNX, TensorFlow, scikit-learn
- 🔗 **Wielobrokerni** - Obsługa FX/CFD, krypto i MT4/MT5 bridge
- 🔒 **Bezpieczny tunelowaie** - Ngrok, LocalTunnel, Cloudflare Tunnel i więcej
- 🐳 **Docker Ready** - Pełna konteneryzacja z docker-compose

## 🚀 Szybki start

```bash
# Klonuj repozytorium
git clone https://github.com/szarastrefa/lean-trading-bot-stack.git
cd lean-trading-bot-stack

# Uruchom instalator
./install.sh

# Lub ręcznie z docker-compose
cp .env.example .env
# Edytuj .env z własnymi kluczami API
docker-compose up --build
```

## 📋 Wspierani brokerzy

### FX/CFD
- XM, IC Markets, RoboForex
- InstaForex, FBS, XTB
- Admiral Markets, IG Group, Plus500
- SabioTrade

### Krypto/Exchange
- Binance, Coinbase Pro, Kraken
- Bitstamp, Bitfinex, Gemini
- Huobi, OKX, Bybit, KuCoin

### MT4/MT5 Integration
- Natywny bridge adapter
- EA server proxy

## 📁 Struktura projektu

```
├── README.md              # Ten plik
├── docker-compose.yml     # Orkiestracja kontenerów
├── install.sh            # Interaktywny instalator
├── .env.example          # Przykład konfiguracji
├── docs/                 # Dokumentacja
│   ├── INSTALL.md       # Instrukcje instalacji
│   ├── TUNNELING.md     # Konfiguracja tunelowania
│   ├── BROKERS.md       # Konfiguracja brokerów
│   └── SECURITY.md      # Wytyczne bezpieczeństwa
├── docker/              # Dockerfile'y
│   ├── lean/
│   ├── webui/
│   └── ml-runtime/
├── webui/               # Frontend i backend WebUI
│   ├── frontend/        # React aplikacja
│   └── backend/         # Flask API
├── lean/                # Konfiguracje LEAN
│   ├── config/         # Pliki konfiguracyjne
│   ├── adapters/       # Adaptery brokerów
│   └── strategies/     # Przykładowe strategie
├── models/              # Modele ML i przykłady
│   ├── examples/       # Przykładowe modele
│   └── converters/     # Konwertery formatów
└── .github/
    └── workflows/      # CI/CD pipelines
```

## 🔧 Opcje tunelowania

- **Ngrok** - Najpopularniejszy, płatne domeny niestandardowe
- **LocalTunnel** - Darmowy, prosty w użyciu
- **Serveo** - SSH-based tunelowanie
- **Cloudflare Tunnel** - Enterprise-grade security
- **PageKite** - Niezawodny, płatny
- **Telebit** - Open source alternatywa

## 📖 Dokumentacja

- [📦 Instalacja](./docs/INSTALL.md) - Szczegółowe instrukcje instalacji
- [🌐 Tunelowanie](./docs/TUNNELING.md) - Konfiguracja wszystkich opcji tunelowania
- [🏦 Brokerzy](./docs/BROKERS.md) - Konfiguracja API brokerów z przykładami
- [🔒 Bezpieczeństwo](./docs/SECURITY.md) - Wytyczne produkcyjne i hardening

## ⚡ Technologie

- **Backend**: QuantConnect LEAN (C#), Flask (Python)
- **Frontend**: React + Bootstrap
- **ML Runtime**: ONNX Runtime, TensorFlow, scikit-learn
- **Konteneryzacja**: Docker + Docker Compose
- **Proxy/Tunelowanie**: Nginx, różne usługi tunelowania

## 🤝 Wkład

Zachęcamy do współpracy! Przeczytaj [CONTRIBUTING.md](./CONTRIBUTING.md) i prześlij pull request.

## 📄 Licencja

Apache 2.0 License - zobacz [LICENSE](./LICENSE)

## ⚠️ Disclaimer

Ten projekt jest przeznaczony wyłącznie do celów edukacyjnych. Trading wiąże się z ryzykiem straty kapitału. Zawsze przestrzegaj lokalnych regulacji finansowych.

---

⭐ **Jeśli projekt Ci się podoba, zostaw gwiazdkę!** ⭐