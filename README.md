![https://www.augustash.com](http://augustash.s3.amazonaws.com/logos/ash-inline-color-500.png)

**This container is not currently aimed at public consumption. It exists as an internal tool for August Ash containers.**

## About

Percona Server is a fork of the MySQL relational database management system created by Percona. It aims to retain close compatibility to the official MySQL releases, while focusing on performance and increased visibility into server operations.

## TL;DR

```bash
docker-compose up -d
```

## Usage

Start a new container from the image, expose the proper ports, and mount a volume for persistence:

```bash
docker run -d -P \
  -v ~/volumes/data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD="root" \
  augustash/percona-server:5.7
```

The first time you run the container, it will check for an existing database. If one isn't found, a default will be created. You must include the `MYSQL_ROOT_PASSWORD` variable.

You can test the connection to your MySQL instance with a throw-away container:

```bash
docker run -it --rm \
  --link <DB CONTAINER>:db_host \
  mysql \
  /bin/bash -c 'mysql -hdb_host -uroot -p'
```

**Note:** If your database container was started with `docker-compose` and has a network, you'll need to link it differently:

```bash
docker run -it --rm \
  --link <DB CONTAINER>:db_host \
  --net <NETWORK NAME>
  mysql \
  /bin/bash -c 'mysql -hdb_host -uroot -p'
```

You can find available networks by:

```bash
docker network ls
```

## Configuration

### Mount Custom Configuration

If you need to change configuration values, the best option is to mount your own custom configuration:

```bash
docker run -d -P \
  -v $(pwd)/mysqld.cnf:/config/mysql/conf.d/mysqld.cnf \
  -e MYSQL_ROOT_PASSWORD="root" \
  augustash/percona-server:5.7
```

### Set `root` Password

You must specify a password for the administrative user account unless the container will be connecting to an existing data volume:

```bash
docker run -d -P \
  -e MYSQL_ROOT_PASSWORD="root" \
  augustash/percona-server:5.7
```

### Create a new user

To use a specific username or password, you can set the environment variables `MYSQL_USER` and `MYSQL_PASS` when creating a container (if `MYSQL_DATABASE` is set, the user created will have permissions to the new database):

```bash
docker run -d -P \
  -e MYSQL_ROOT_PASSWORD="root" \
  -e MYSQL_USER="admin" \
  -e MYSQL_PASS="1234567890" \
  augustash/percona-server:5.7
```

### Import Existing Databases

If you need to migrate an existing MySQL-based database into your container, run through the following steps.

On the existing MySQL server, create a SQL backup of your structure & data:

```bash
mysqldump -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_NAME \
  --force --triggers --single-transaction --opt --skip-lock-tables \
  > /tmp/$MYSQL_NAME.sql
```

Import your SQL backup into your container:

```bash
docker run -it --rm \
  --link <DB CONTAINER>:db_host \
  --net <NETWORK NAME>
  -v /tmp:/backups \
  --entrypoint /usr/bin/mysql
  augustash/percona-server:5.7 \
  '-hdb_host -uroot -p $MYSQL_NAME < /backups/$MYSQL_NAME.sql'
```

### Backups

Percona's XtraBackup utility is included, which makes creating backups of your database very easy. To create a hot backup while the server is running:

```bash
docker exec -it <DB CONTAINERE> /usr/bin/innobackupex --user=<USER> --password=<PASS> /backups
```

For additional XtraBackup options:

```bash
docker exec -it <DB CONTAINERE> /usr/bin/innobackupex --help
```

```bash
docker run --rm --volumes-from <DATA CONTAINER> -v $(pwd):/data ubuntu /bin/bash -c 'tar cvf /data/backup.tar /backups/*'
```

### User/Group Identifiers

To help avoid nasty permissions errors, the container allows you to specify your own `PUID` and `PGID`. This can be a user you've created or even root (not recommended).

### Environment Variables

The following variables can be set and will change how the container behaves. You can use the `-e` flag, an environment file, or your Docker Compose file to set your preferred values. The default values are shown:

- `PUID`=501
- `PGID`=20
- `MYSQL_ROOT_PASSWORD`
- `MYSQL_ALLOW_EMPTY_PASSWORD`
- `MYSQL_RANDOM_ROOT_PASSWORD`
- `MYSQL_ONETIME_PASSWORD`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `MYSQL_PASSWORD`
- `MYSQL_OPTS`
