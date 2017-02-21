#!/usr/bin/with-contenv bash

DATADIR="$(mysqld --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"

if [ ! -d "$DATADIR/mysql" ]; then
    # root password is required
    if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
        echo >&2 "Error: database is uninitialized and no root password was set"
        echo >&2 "  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD or MYSQL_RANDOM_ROOT_PASSWORD"
        exit 1
    fi

    echo "==> An empty or uninitialized database was detected in $DATADIR"
    echo "-----> Initializing database..."
    mysqld --initialize-insecure
    echo "-----> Done!"

    echo "==> starting MySQL in order to setup passwords"
    mysqld --skip-networking &
    PID="$!"
    MYSQL=(mysql --protocol=socket -uroot)

    # For thirty seconds, poll if mysql is responding
    echo "-----> testing if DB is up"
    for i in {30..0}; do
        if echo 'SELECT 1' | "${MYSQL[@]}" &> /dev/null; then
            break
        fi
        echo '-----> MySQL init process in progress...'
        sleep 1
    done
    if [ "$1" = 0 ]; then
        echo >&2 "==> MySQL init process failed"
        exit 1
    fi

    # set default credentials
    echo "-----> securing MySQL root user"
    if [ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
        MYSQL_ROOT_PASSWORD="$(pwgen -1 32)"
        echo "-----> generated MySQL root password: $MYSQL_ROOT_PASSWORD"
    fi

    "${MYSQL[@]}" <<-EOSQL
        SET @@SESSION.SQL_LOG_BIN=0;
        DELETE FROM mysql.user;
        DROP DATABASE IF EXISTS test;
        CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
        GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
        GRANT SUPER ON *.* TO 'root'@'%' WITH GRANT OPTION;
        FLUSH PRIVILEGES;
EOSQL

    if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
        MYSQL+=( -p"${MYSQL_ROOT_PASSWORD}" )
    fi

    # setup named database
    if [ ! -z "$MYSQL_DATABASE" ]; then
        echo "-----> creating database $MYSQL_DATABASE"
        echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;" | "${MYSQL[@]}"
        MYSQL+=( "$MYSQL_DATABASE" )
    fi

    # add additional user
    if [ -z "$MYSQL_USER" -a -z "$MYSQL_PASSWORD" ]; then
        echo "-----> creating MySQL user $MYSQL_USER"
        echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" | "${MYSQL[@]}"

        if [ ! -z "$MYSQL_DATABASE" ]; then
            echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%';" | "${MYSQL[@]}"
        fi

        echo 'FLUSH PRIVILEGES;' | "${MYSQL[@]}"
    fi

    # one-use password
    if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
        "${MYSQL[@]}" <<-EOSQL
            ALTER USER 'root'@'%' PASSWORD EXPIRE;
EOSQL
    fi

    # finish up
    echo "==> stopping MySQL after setting up passwords"
    if ! kill -s TERM "$PID" || ! wait "$PID"; then
        echo >&2 "==> MySQL init process failed"
        exit 1
    fi
    echo "-----> Done!"
else
    echo "==> Using existing database"
fi
