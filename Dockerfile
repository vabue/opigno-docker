FROM php:7.0-apache

RUN a2enmod rewrite

RUN apt-get update && apt-get -y install git mysql-client vim-tiny wget httpie unzip

# Suppressing menu to choose keyboard layout
# COPY ./keyboard /etc/default/keyboard

# install the PHP extensions we need
RUN apt-get install -y libpng12-dev libjpeg-dev libpq-dev zlib1g-dev \
#	&& apt-get install -y wkhtmltopdf openssl build-essential xorg libssl-dev \ # to install wkhtmltopdf we need to suppress menu to choose keyboard layout
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&&  docker-php-ext-install gd mbstring pdo pdo_mysql pdo_pgsql zip

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Install Drush 6.
RUN composer global require drush/drush:6.*
RUN composer global update
RUN ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Add drush comand https://www.drupal.org/project/registry_rebuild
RUN wget http://ftp.drupal.org/files/projects/registry_rebuild-7.x-2.5.tar.gz && \
    tar xzf registry_rebuild-7.x-2.5.tar.gz && \
    rm registry_rebuild-7.x-2.5.tar.gz && \
    mv registry_rebuild /root/.composer/vendor/drush/drush/commands

WORKDIR /var/www/html

ENV OPIGNO_VERSION 7.x-1.24

RUN curl -fSL "https://ftp.drupal.org/files/projects/opigno_lms-${OPIGNO_VERSION}-core.tar.gz" -o drupal.tar.gz \
  && tar -xz --strip-components=1 -f drupal.tar.gz \
  && rm drupal.tar.gz \
  && chown -R www-data:www-data sites

# enabling better way to print certificates
WORKDIR /var/www/html/sites/all/libraries
RUN ln -s /usr/bin/wkhtmltopdf.sh wkhtmltopdf

# PHP.ini settings for Opigno to work
RUN touch /usr/local/etc/php/conf.d/memory-limit.ini && echo "memory_limit=512M" >> /usr/local/etc/php/conf.d/memory-limit.ini \
	&& touch /usr/local/etc/php/conf.d/max-execution-time.ini && echo "max_execution_time=120" >> /usr/local/etc/php/conf.d/max-execution-time.ini

# Install pdf.js to show pdf slides and Tincan PHP
RUN mkdir pdf.js && cd pdf.js \
	&& wget https://github.com/mozilla/pdf.js/releases/download/v1.6.210/pdfjs-1.6.210-dist.zip \
	&& unzip ./pdfjs-1.6.210-dist.zip && rm ./pdfjs-1.6.210-dist.zip \
	&& cd .. && wget https://github.com/RusticiSoftware/TinCanPHP/archive/1.0.0.zip \
	&& unzip ./1.0.0.zip && rm ./1.0.0.zip && mv ./TinCanPHP-1.0.0 ./TinCanPHP

# TODO cron run every hour


# TODO add entrypoint.sh & default.settings.php to my folder
# COPY entrypoint.sh /entrypoint.sh
# COPY default.settings.php sites/default/settings.php

# RUN chmod 755 /*.sh
# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["apache2-foreground"]
