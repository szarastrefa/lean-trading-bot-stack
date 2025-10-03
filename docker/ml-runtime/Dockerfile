# LEAN Trading Bot Stack - ML Runtime Dockerfile
# Supports ONNX, TensorFlow, PyTorch, and scikit-learn models

FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r mluser && useradd -r -g mluser mluser

# Set working directory
WORKDIR /app

# Copy requirements first (for better caching)
COPY requirements.txt .

# Install Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create directories
RUN mkdir -p models temp logs notebooks

# Set permissions
RUN chown -R mluser:mluser /app

# Switch to non-root user
USER mluser

# Expose ports
EXPOSE 5001 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:5001/health || exit 1

# Start both Jupyter Lab and ML API service
CMD ["/app/start.sh"]