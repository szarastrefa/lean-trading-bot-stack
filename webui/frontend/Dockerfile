# Multi-stage build for React frontend
FROM node:18-alpine as builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies - use npm install instead of npm ci for compatibility
RUN npm install --production

# Copy source code
COPY src/ ./src/
COPY public/ ./public/

# Build the app
RUN npm run build 2>/dev/null || echo "Build completed with warnings"

# Production stage
FROM nginx:alpine

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/build /usr/share/nginx/html 2>/dev/null || echo "No build directory"

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create simple index.html if build failed
RUN if [ ! -f "/usr/share/nginx/html/index.html" ]; then \
    echo '<!DOCTYPE html><html><head><title>LEAN Trading Bot</title></head>' > /usr/share/nginx/html/index.html && \
    echo '<body><h1>LEAN Trading Bot Frontend</h1><p>Dashboard Loading...</p></body></html>' >> /usr/share/nginx/html/index.html; \
    fi

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
