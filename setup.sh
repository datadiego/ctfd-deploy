#!/bin/bash

# Configuración
EMAIL=$1
DOMAIN=$2

if [ -z "$EMAIL" ] || [ -z "$DOMAIN" ]; then
    echo "❌ Uso: $0 <email> <dominio>"
    exit 1
fi

# Paso 1: Instalación de dependencias
echo "🔧 Instalando dependencias..."
sudo apt update
sudo apt install -y docker docker-compose certbot

sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
sudo ufw reload

# Paso 2: Creación de carpetas
echo "📁 Creando carpetas necesarias..."
mkdir -p nginx/certs nginx/www ctfd_data

# Paso 3: Obtener certificados SSL con Certbot
echo "🗝️ Obteniendo certificados SSL..."
sudo certbot certonly --standalone --agree-tos --no-eff-email --email "$EMAIL" -d "$DOMAIN" -d "www.$DOMAIN"

# Paso 4: Copiar certificados en la carpeta de Docker
echo "📦 Copiando certificados..."
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ./nginx/certs/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ./nginx/certs/

# Paso 5: Ajustar permisos
echo "🔒 Ajustando permisos..."
sudo chown $(whoami):$(whoami) ./nginx/certs/*
chmod 600 ./nginx/certs/*

# Paso 6: Generar nginx.conf
echo "📝 Generando nginx.conf..."
sed "s/ejemplo.com/$DOMAIN/g; s/wwww/www/g" nginx/nginx.conf.example > nginx/nginx.conf

# Paso 7: Docker Compose
echo "🐳 Lanzando Docker Compose..."
docker-compose up -d

# Paso 8: Añadir renovación automática
echo "⏰ Configurando renovación automática de certificados..."
(crontab -l ; echo "0 0 1 * * certbot renew && docker compose restart nginx") | crontab -

echo "✅ Todo listo. Tu CTFd debería estar disponible en https://$DOMAIN"