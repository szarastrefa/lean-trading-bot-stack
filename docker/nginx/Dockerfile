FROM nginx:alpine

# Kopiuj konfigurację nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Utwórz katalog dla certyfikatów SSL (opcjonalne)
RUN mkdir -p /etc/nginx/ssl

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]