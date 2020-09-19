FROM php:7-cli-alpine3.12

ARG IFM_COMMIT_SHA=829d1d46316a392714b044b6089a74ae4ec30300
ADD https://github.com/misterunknown/ifm/archive/${IFM_COMMIT_SHA}.tar.gz \
    /tmp/ifm.tar.gz

# only necessary environment variables
ENV IFM_ROOT_DIR="/var/www"    \
    IFM_ROOT_PUBLIC_URL="/www" \
    IFM_TMP_DIR="/tmp"

RUN apk add --no-cache --update \
        libbz2 \
        libcap \
        libzip \
        openldap-dev \
        sudo \
 && apk add --no-cache --update --virtual .build-deps \
        bzip2 \
        bzip2-dev \
        libzip-dev \
 && docker-php-ext-install bz2 \
                           ldap \
                           zip \
 && apk del --no-cache --purge .build-deps \
 # allow php binary to bind ports <1000, even if $USER != root
 && /usr/sbin/setcap CAP_NET_BIND_SERVICE=+eip \
                     /usr/local/bin/php \
 && deluser xfs \
 && deluser www-data \
 # sudo: workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1773148
 && echo "Set disable_coredump false" > /etc/sudo.conf \
 && rm -rf /var/www/html \
 && mkdir -p /usr/local/share/webapps/ifm \
 && chown -R 33:33 /var/www \
 && ln -s /var/www /usr/local/share/webapps/ifm/www \
 && cd /tmp \
 && tar xvzf ifm.tar.gz \
 && mv ifm-${IFM_COMMIT_SHA} /usr/src/ifm \
 && /usr/src/ifm/compiler.php --languages=all \
 && cp /usr/src/ifm/dist/ifm.php \
       /usr/local/share/webapps/ifm/index.php \
 && cp /usr/src/ifm/docker/php.ini \
       /usr/local/share/webapps/ifm/ \
 && cp /usr/src/ifm/docker/docker-startup.sh \
       /usr/local/bin \
 && rm -rf /usr/src/ifm \
           /tmp/*

WORKDIR /usr/local/share/webapps/ifm

EXPOSE 80

CMD /usr/local/bin/docker-startup.sh
