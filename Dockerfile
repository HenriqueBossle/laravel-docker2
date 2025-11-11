# Etapa 1: Imagem base do PHP com Apache
FROM php:8.3-apache

# Instalar dependências do sistema e extensões necessárias do Laravel
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libjpeg-dev libfreetype6-dev zip unzip libonig-dev libxml2-dev libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd \
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
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Ajustar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Configurar o Apache para servir a partir de /public
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Expor a porta padrão do Apache
EXPOSE 8001

# Comando de inicialização:
# - Executa as migrações (com fallback caso falhem)
# - Inicia o Apache
CMD php artisan migrate --force || true && apache2-foreground