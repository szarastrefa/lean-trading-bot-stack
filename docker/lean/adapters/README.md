# LEAN Trading Adapters

This directory contains broker adapters for connecting LEAN to various trading platforms.

## Available Adapters

- `binance.py` - Binance cryptocurrency exchange adapter
- `xm.py` - XM forex broker adapter  
- `mt5_bridge.py` - MetaTrader 5 bridge adapter
- `paper_trading.py` - Paper trading simulation adapter

## Configuration

Each adapter requires specific configuration in the `.env` file:

```bash
# Binance
BINANCE_API_KEY=your_api_key
BINANCE_SECRET_KEY=your_secret_key

# XM Broker
XM_LOGIN=your_login
XM_PASSWORD=your_password
XM_SERVER=your_server

# MT5
MT5_LOGIN=your_login
MT5_PASSWORD=your_password
MT5_SERVER=your_server
```

## Usage

Adapters are automatically loaded based on configuration in `config.json`.
