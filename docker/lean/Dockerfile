# LEAN Trading Bot Stack - QuantConnect LEAN Engine Dockerfile
# Based on official QuantConnect LEAN image with custom modifications

FROM quantconnect/lean:latest

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for ML integration
RUN pip3 install --no-cache-dir \
    onnxruntime \
    tensorflow \
    scikit-learn \
    pandas \
    numpy \
    requests \
    websocket-client

# Create directories
RUN mkdir -p /opt/lean/config \
             /opt/lean/strategies \
             /opt/lean/data \
             /opt/lean/results \
             /opt/lean/adapters \
             /opt/lean/models

# Copy custom LEAN configurations
COPY config/ /opt/lean/config/
COPY adapters/ /opt/lean/adapters/
COPY strategies/ /opt/lean/strategies/

# Set permissions
RUN chmod -R 755 /opt/lean/

# Working directory
WORKDIR /opt/lean

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Default command
CMD ["dotnet", "QuantConnect.Lean.Launcher.dll"]