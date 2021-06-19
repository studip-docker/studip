#!/bin/bash
set -e

STUDIP='/var/www/studip'
CONFIGFILE="$STUDIP/config/config_local.inc.php"
DOCKERCONFIGFILE="/config/config_local.inc.php"
CONF="$STUDIP/config/config.inc.php"

# Check if we have a config
if [ ! -f $CONFIGFILE ]; then
    echo "Setting up new config"

    cp "$DOCKERCONFIGFILE" "$CONFIGFILE" 
    cp "$CONF.dist" "$CONF" 
fi

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

# Check if the connected database has tables, otherwise install the database
if [[ $(mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "show tables;" --batch | wc -l) -eq 0 ]]; then

    # Setup mysql database
    echo "INSTALL DB"
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip.sql
    echo "INSTALL DEFAULT DATA"
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_default_data.sql
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_resources_default_data.sql

    echo "INSTALL ROOTUSER"
    mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_root_user.sql

    # Check if demodata is required
    if [ ! -z $DEMO_DATA ]; then
        echo "INSTALL DEMODATA"
        mysql -f -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}/db/studip_demo_data.sql
    fi

    echo "INSTALLATION FINISHED"
else
    echo "Found some SQL table. Skipping installation"
fi

if [ ! -z $AUTO_MIGRATE ]; then
    echo "Migrate Instance"
    
    # If migrate fails start instance anyway
    php "$STUDIP/cli/migrate.php" || true
    echo "Migration finished"
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- apache2-foreground "$@"
fi

exec "$@"
