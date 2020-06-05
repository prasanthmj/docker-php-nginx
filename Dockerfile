FROM alpine:3.11
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight container with Nginx 1.16 & PHP-FPM 7.3 based on Alpine Linux."

# Install packages
RUN apk --no-cache add php7 php7-fpm php7-pdo php7-pdo_mysql php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-ctype php7-session \
    php7-mbstring php7-tokenizer php7-gd nginx supervisor curl

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

COPY config/php-common.conf /etc/nginx/snippets/php-common.conf

COPY config/nginx-common.conf /etc/nginx/snippets/nginx-common.conf

COPY config/default.conf /etc/nginx/conf.d/default.conf


# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

RUN adduser --disabled-password --no-create-home --uid 998 k8s k8s
# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R k8s.k8s /run && \
  chown -R k8s.k8s /var/lib/nginx && \
  chown -R k8s.k8s /var/log/nginx

# Switch to use a non-root user from here on
USER k8s

# Add application
WORKDIR /var/www/html
#COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
#HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
