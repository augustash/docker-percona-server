![https://www.augustash.com](http://augustash.s3.amazonaws.com/logos/ash-inline-color-500.png)

# Percona Server Image

**This `mysql` container is not currently aimed at public consumption. It exists as an internal tool for August Ash development and is built upon [Phusion](http://phusion.github.io/baseimage-docker/).**

## Usage

To build the Docker image, clone this repository and from the project directory run:

```
docker-compose build
```

Now start a new container from the image, expose the proper ports, and mount a volume for persistence:

```
docker-compose up -d
```

You can also start a container outside of Docker Compose:

```
docker run -d -P \
  -v ~/volumes/data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD="root" \
  augustash/mysql
```

The first time you run the container, it will check for an existing database. If one isn't found, the default will be created and you must include the `MYSQL_ROOT_PASSWORD` variable.

You can test the connection to your MySQL instance with a throw-away container:

```
docker run -it --rm \
    --link db:db_host \
    mysql \
    /bin/bash -c 'mysql -hdb_host -uroot -p'
```

### Set `root` Password

You must specify a password for the administrative user account unless the container will be connecting to an existing data volume:

```bash
docker run -d -P \
  -e MYSQL_ROOT_PASSWORD="root" \
  augustash/mysql
```

### Create a new user

To use a specific username or password, you can set the environment variables `MYSQL_USER` and `MYSQL_PASS` when creating a container (if `MYSQL_DATABASE` is set, the user created will have permissions to the new database):

```
docker run -d -P \
  -e MYSQL_ROOT_PASSWORD="root" \
  -e MYSQL_USER="admin" \
  -e MYSQL_PASS="1234567890" \
  augustash/mysql
```

### Import Existing Databases

If you need to migrate an existing MySQL-based database into your container, run through the following steps.

On the existing MySQL server, create a SQL backup of your structure & data:

```
mysqldump -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_NAME \
    --force --triggers --single-transaction --opt --skip-lock-tables \
    > /tmp/$MYSQL_NAME.sql
```

Import your SQL backup into your container:

```bash
docker run -it --rm \
    --link db:db_host \
    -v /tmp:/data \
    augustash/mysql \
    /bin/bash -c 'mysql -hdb_host -uroot -p $MYSQL_NAME < /data/$MYSQL_NAME.sql'
```

### Backups

Percona's XtraBackup utility is included, which makes creating backups of your database very easy. To create a hot backup while the server is running:

```
docker exec -it <RUNNING_CONTAINER_NAME> innobackupex --user=<USER> --password=<PASS> /backups
```

For additional XtraBackup options:

```bash
docker exec -it <RUNNING_CONTAINER_NAME> innobackupex --help
```


```bash
docker run --rm --volumes-from <DATA_CONTAINER> -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /backups/*
```

## Volumes

Three mount points for connecting data volumes from the host or other containers are available.

* `/backups` - XtraBackup archives
* `/var/lib/mysql` - MySQL data files
* `/var/log/mysql` - MySQL log files

## Exposed Ports

* Port `3306`

## Available Environment Variables

* `SKIP_UPDATE`
* `MYSQL_PORT`
* `MYSQL_ROOT_PASSWORD`
* `MYSQL_DATABASE`
* `MYSQL_USER`
* `MYSQL_PASSWORD`
* `MYSQL_OPTS`
* `MYSQL_RANDOM_ROOT_PASSWORD`
* `MYSQL_ALLOW_EMPTY_PASSWORD`
* `MYSQL_ONETIME_PASSWORD`
* `MYSQL_BULK_INSERT_BUFFER_SIZE`
* `MYSQL_CONCURRENT_INSERT`
* `MYSQL_CONNECT_TIMEOUT`
* `MYSQL_KEY_BUFFER_SIZE`
* `MYSQL_MAX_ALLOWED_PACKET`
* `MYSQL_MAX_HEAP_TABLE_SIZE`
* `MYSQL_MYISAM_SORT_BUFFER_SIZE`
* `MYSQL_READ_BUFFER_SIZE`
* `MYSQL_READ_RND_BUFFER_SIZE`
* `MYSQL_SORT_BUFFER_SIZE`
* `MYSQL_TABLE_OPEN_CACHE`
* `MYSQL_THREAD_CACHE_SIZE`
* `MYSQL_THREAD_STACK`
* `MYSQL_TMP_TABLE_SIZE`
* `MYSQL_WAIT_TIMEOUT`
* `MYSQL_QUERY_CACHE_LIMIT`
* `MYSQL_QUERY_CACHE_SIZE`
* `MYSQL_INNODB_BUFFER_POOL_SIZE`
* `MYSQL_INNODB_LOG_BUFFER_SIZE`
* `MYSQL_INNODB_LOG_FILE_SIZE`
* `MYSQL_INNODB_FILE_PER_TABLE`
* `MYSQL_INNODB_OPEN_FILES`
* `MYSQL_INNODB_IO_CAPACITY`
* `MYSQL_INNODB_THREAD_CONCURRENCY`
* `MYSQL_INNODB_LOCK_WAIT_TIMEOUT`
* `MYSQL_INNODB_FLUSH_LOG_AT_TRX_COMMIT`
* `MYSQL_INNODB_FLUSH_METHOD`
