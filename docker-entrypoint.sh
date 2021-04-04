#!/bin/bash
set -e

STUDIP='/var/www/studip'
CONFIGFILE="$STUDIP/config/config_local.inc.php"
CONF="$STUDIP/config/config.inc.php"

# Check if we have a config
if [ ! -f $CONFIGFILE ]; then
    echo "Setting up new config"

    cp "$CONFIGFILE.dist.docker" "$CONFIGFILE" 
    cp "$CONF.dist" "$CONF" 

    # Setup mysql database
    echo "Waiting for db to come up"

    # If we deal with a socket and mysql host is not set overwrite the host to make MYSQL work
    if [ -z $MYSQL_HOST ]; then
        MYSQL_HOST='localhost'
    fi;

# wait until MySQL is really available
    maxcounter=45
 
    counter=1
    while ! mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD -e "show databases;" > /dev/null 2>&1; do
        sleep 1
        counter=`expr $counter + 1`
        if [ $counter -gt $maxcounter ]; then
            >&2 echo "We have been waiting for MySQL too long already; failing."
            exit 1
        fi;
    done

    echo "Database answered"

    echo "INSTALL DB"
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip.sql
    echo "INSTALL DEFAULT DATA"
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_default_data.sql
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_resources_default_data.sql

    echo "INSTALL ROOTUSER"
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_root_user.sql

    echo "INSTALL DEMODATA"
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_demo_data.sql

    echo "INSTALLATION FINISHED"
fi

if [ ! -z $AUTO_MIGRATE ]; then
    echo "Migrate Instance"
    php "$STUDIP/cli/migrate.php"
    echo "Migration finished"
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- apache2-foreground "$@"
fi

exec "$@"
