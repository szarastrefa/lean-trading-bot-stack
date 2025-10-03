#!/bin/bash

# LEAN Trading Bot Stack - ML Runtime Startup Script

set -e

echo "Starting ML Runtime services..."

# Start Jupyter Lab in background (if enabled)
if [ "${JUPYTER_ENABLE_LAB:-yes}" = "yes" ]; then
    echo "Starting Jupyter Lab on port 8888..."
    
    if [ -n "$JUPYTER_TOKEN" ]; then
        TOKEN_PARAM="--IdentityProvider.token=$JUPYTER_TOKEN"
    else
        TOKEN_PARAM="--IdentityProvider.token=''"
    fi
    
    jupyter lab \
        --ip=0.0.0.0 \
        --port=8888 \
        --no-browser \
        --allow-root \
        --notebook-dir=/app/notebooks \
        $TOKEN_PARAM &
    
    JUPYTER_PID=$!
    echo "Jupyter Lab started with PID: $JUPYTER_PID"
fi

# Start ML API service
echo "Starting ML API service on port 5001..."
python ml_api.py &
API_PID=$!
echo "ML API started with PID: $API_PID"

# Wait for services to be ready
sleep 5

# Health check
echo "Performing health check..."
curl -f http://localhost:5001/health || {
    echo "ML API health check failed"
    exit 1
}

if [ "${JUPYTER_ENABLE_LAB:-yes}" = "yes" ]; then
    curl -f http://localhost:8888/api || {
        echo "Warning: Jupyter Lab health check failed"
    }
fi

echo "All ML Runtime services started successfully"

# Keep the container running and monitor processes
while true; do
    if ! kill -0 $API_PID 2>/dev/null; then
        echo "ML API service died, restarting..."
        python ml_api.py &
        API_PID=$!
    fi
    
    if [ "${JUPYTER_ENABLE_LAB:-yes}" = "yes" ] && ! kill -0 $JUPYTER_PID 2>/dev/null; then
        echo "Jupyter Lab died, restarting..."
        jupyter lab \
            --ip=0.0.0.0 \
            --port=8888 \
            --no-browser \
            --allow-root \
            --notebook-dir=/app/notebooks \
            $TOKEN_PARAM &
        JUPYTER_PID=$!
    fi
    
    sleep 30
done