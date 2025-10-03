#!/bin/bash

# LEAN Trading Bot Stack - Universal Tunnel Starter

set -e

TUNNEL_TYPE=${TUNNEL_TYPE:-none}
TARGET_URL=${TARGET_URL:-http://nginx:80}

echo "Starting tunnel service: $TUNNEL_TYPE"
echo "Target URL: $TARGET_URL"

case $TUNNEL_TYPE in
    "ngrok")
        echo "Starting Ngrok tunnel..."
        if [ -z "$NGROK_AUTH_TOKEN" ]; then
            echo "ERROR: NGROK_AUTH_TOKEN is required for Ngrok"
            exit 1
        fi
        
        # Configure ngrok
        ngrok config add-authtoken $NGROK_AUTH_TOKEN
        
        # Start ngrok tunnel
        if [ -n "$NGROK_SUBDOMAIN" ]; then
            ngrok http $TARGET_URL --subdomain=$NGROK_SUBDOMAIN
        else
            ngrok http $TARGET_URL
        fi
        ;;
        
    "localtunnel")
        echo "Starting LocalTunnel..."
        if [ -n "$LOCALTUNNEL_SUBDOMAIN" ]; then
            lt --port 80 --local-host nginx --subdomain $LOCALTUNNEL_SUBDOMAIN
        else
            lt --port 80 --local-host nginx
        fi
        ;;
        
    "serveo")
        echo "Starting Serveo tunnel..."
        if [ -n "$SERVEO_SUBDOMAIN" ]; then
            ssh -o StrictHostKeyChecking=no -R $SERVEO_SUBDOMAIN:80:nginx:80 serveo.net
        else
            ssh -o StrictHostKeyChecking=no -R 80:nginx:80 serveo.net
        fi
        ;;
        
    "cloudflare")
        echo "Starting Cloudflare Tunnel..."
        if [ -z "$CLOUDFLARE_TUNNEL_TOKEN" ]; then
            echo "ERROR: CLOUDFLARE_TUNNEL_TOKEN is required for Cloudflare Tunnel"
            exit 1
        fi
        
        cloudflared tunnel run --token $CLOUDFLARE_TUNNEL_TOKEN
        ;;
        
    "pagekite")
        echo "Starting PageKite..."
        if [ -z "$PAGEKITE_KITE" ] || [ -z "$PAGEKITE_SECRET" ]; then
            echo "ERROR: PAGEKITE_KITE and PAGEKITE_SECRET are required for PageKite"
            exit 1
        fi
        
        python3 -m pagekite 80 $PAGEKITE_KITE --secret=$PAGEKITE_SECRET
        ;;
        
    "telebit")
        echo "Starting Telebit..."
        if [ -n "$TELEBIT_TOKEN" ]; then
            telebit http 80 --token=$TELEBIT_TOKEN
        else
            telebit http 80
        fi
        ;;
        
    "none")
        echo "No tunnel service configured"
        echo "Application will be available only locally"
        # Keep container running
        tail -f /dev/null
        ;;
        
    *)
        echo "ERROR: Unknown tunnel type: $TUNNEL_TYPE"
        echo "Supported types: ngrok, localtunnel, serveo, cloudflare, pagekite, telebit, none"
        exit 1
        ;;
esac