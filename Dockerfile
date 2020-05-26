FROM php:7.2-fpm

ENV NGINX_VERSION 1.15.3

RUN set -x && \
    apt-get update && \
    apt-get install -y vim busybox apt-utils build-essential libtool python-setuptools \
          libpcre3 libpcre3-dev libpcre++-dev zlib1g-dev openssl libssl-dev \
	  libfreetype6-dev libjpeg62-turbo-dev libpng-dev libfreetype6-dev \
	  libbz2-dev libmcrypt-dev libmhash-dev libxml2-dev libmemcached-dev \
    && docker-php-source extract \
    && docker-php-ext-install -j$(nproc) mysqli pdo_mysql \
    #&& docker-php-ext-install -j$(nproc) shmop soap sockets sysvmsg sysvsem sysvshm xmlrpc \
    && docker-php-ext-install -j$(nproc) bz2 bcmath gettext xml zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd  \
    && pecl install redis-4.0.1 \
    && pecl install xdebug-2.6.0 \
    && pecl install seaslog \
    && docker-php-ext-enable redis xdebug seaslog \
    && docker-php-source delete \
    && apt-get install -y certbot python-certbot-nginx

ADD files/ /tmp/files/

RUN	set -x && \
	#
	curl -Lk http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | gunzip | tar x -C /tmp/files && \
	#
	#
	cd /tmp/files/nginx-$NGINX_VERSION && \
	#Add user
        mkdir -p /opt/www && \
        useradd -r -s /sbin/nologin -d /opt/www -m -k no www && \
	./configure --prefix=/opt/nginx \
          --user=www --group=www \
          --error-log-path=/var/log/nginx_error.log \
          --http-log-path=/var/log/nginx_access.log \
          --pid-path=/var/run/nginx.pid \
          --with-pcre \
          --with-http_ssl_module \
          --without-mail_pop3_module \
          --without-mail_imap_module \
          --with-http_gzip_static_module && \
	make && make install 
	

RUN cp -f /tmp/files/start.sh /start.sh && \
        chmod +x /start.sh && \
	cp -f /tmp/files/nginx.conf /opt/nginx/conf/nginx.conf && \
        cp -f /tmp/files/supervisord.conf /etc/supervisord.conf && \
        cp -f /tmp/files/docker-php-ext-seaslog.ini /usr/local/etc/php/conf.d/docker-php-ext-seaslog.ini && \
        cp -f /tmp/files/php.ini /usr/local/etc/php/php.ini && \
	cp -f /tmp/files/index.php /opt/www && \
	#
        #
        curl -Lk https://bootstrap.pypa.io/ez_setup.py | python && \
	#Install supervisor
	easy_install supervisor
	
EXPOSE 80 443
ENTRYPOINT ["/start.sh"]
	
	
	
	

