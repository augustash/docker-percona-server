FROM augustash/baseimage:0.9.19-1
MAINTAINER Pete McWilliams <pmcwilliams@augustash.com>

# environment
ENV PERCONA_MAJOR 5.7
ENV PERCONA_VERSION 5.7.16-10-1.xenial
ENV APTLIST \
        apt-transport-https \
        percona-server-client-${PERCONA_MAJOR} \
        percona-server-server-${PERCONA_MAJOR}=${PERCONA_VERSION} \
        percona-toolkit \
        percona-xtrabackup \
        pwgen

# configure system
RUN { \
        echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password password 'unused'; \
        echo percona-server-server-$PERCONA_MAJOR percona-server-server/root_password_again password 'unused'; \
    } | debconf-set-selections && \
    apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5 && \
    echo "deb https://repo.percona.com/apt `lsb_release -cs` main" > /etc/apt/sources.list.d/percona.list && \
    { \
        echo 'Package: *'; \
        echo 'Pin: release o=Percona Development Team'; \
        echo 'Pin-Priority: 998'; \
    } > /etc/apt/preferences.d/percona

# install packages
RUN \
    apt-get -yqq update && \
    apt-get -yqq install --no-install-recommends --no-install-suggests $APTLIST && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# clean up
RUN \
    sed -ri 's/^user\s+=\s+mysql/user = ash/' /etc/mysql/percona-server.conf.d/mysqld.cnf && \
    mkdir -p /backups && \
    chown -R "$PUID":"$PGID" /var/lib/mysql* /var/run/mysqld /var/log/mysql /backups && \
    chmod 777 /var/run/mysqld
RUN \
    sed -Ei 's/^bind-address/#&/' /etc/mysql/percona-server.conf.d/mysqld.cnf && \
    echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/percona-server.conf.d/mysqld.cnf > /tmp/my.cnf && \
    mv /tmp/my.cnf /etc/mysql/percona-server.conf.d/mysqld.cnf

# add scripts
COPY confd/ /etc/confd/
COPY init/ /etc/my_init.d/
COPY services/ /etc/service/
RUN  chmod +x /etc/service/*/run /etc/my_init.d/*.sh

# exports
EXPOSE 3306
VOLUME ["/var/lib/mysql", "/var/log/mysql"]
CMD ["/sbin/my_init"]
