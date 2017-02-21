#!/usr/bin/with-contenv bash

# Set correct permissions because volumes are initially owned by root
echo "==> Setting directory ownership"
chown -Rf "$PUID":"$PGID" \
    /backups \
    /config/mysql \
    /var/lib/mysql* \
    /var/log/mysql \
    /var/run/mysqld
