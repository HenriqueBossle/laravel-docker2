# Etapa 1: Imagem base do PHP com Apache
FROM php:8.3-apache

# Instalar dependências do sistema e extensões necessárias do Laravel
RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libjpeg-dev libfreetype6-dev libonig-dev libxml2-dev libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Habilitar mod_rewrite do Apache (necessário para o Laravel)
RUN a2enmod rewrite

# Definir o diretório de trabalho
WORKDIR /var/www/html

# Copiar o Composer do container oficial
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copiar o código da aplicação
COPY . .

# Instalar dependências PHP (Laravel)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Corrigir permissões (essencial no Render)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Configurar o Apache para servir a partir da pasta /public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Expor a porta padrão usada pelo Render
EXPOSE 80

# Definir o comando inicial:
# - Garante APP_KEY (caso Render ainda não tenha)
# - Roda migrations em produção (ignora erro se já existe)
# - Inicia o Apache
CMD php artisan key:generate --force || true \
    && php artisan migrate --force || true \
    && apache2-foreground
