#!/bin/bash

# Set correct permissions because volumes are initially owned by root
echo "==> Setting volume ownership"
chown -Rf "$PUID":"$PGID" \
    /backups \
    /var/lib/mysql* \
    /var/log/mysql \
    /var/run/mysqld
echo "-----> Done!"
