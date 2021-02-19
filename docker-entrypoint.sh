#!/bin/bash
set -e

STUDIP='/var/www/studip'
CONFIGFILE="$STUDIP/config/config_local.inc.php"
CONF="$STUDIP/config/config.inc.php"

# Check if we have a config
if [ ! -f $CONFIGFILE ]; then
    echo "Setting up new config"

    # Setup config file
    sed "
	/\$DB_STUDIP_HOST/ s/\"localhost\"/\"${MYSQL_HOST}\"/
	/\$DB_STUDIP_USER/ s/\"\"/\"${MYSQL_USER}\"/
    /\$DB_STUDIP_PASSWORD/ s/\"\"/\"${MYSQL_PASSWORD}\"/
    /\$DB_STUDIP_DATABASE/ s/\"studip\"/\"${MYSQL_DATABASE}\"/
    s#//\$ABSOLUTE_URI_STUDIP = 'https://www.studip.de/';#if (isset(\$_ENV['PROXY_URL'])) \$ABSOLUTE_URI_STUDIP = \$_ENV['PROXY_URL'];#
    s#//\$ASSETS_URL = 'https://www.studip.de/assets/';#if (isset(\$_ENV['PROXY_URL'])) \$ASSETS_URL = \$_ENV['PROXY_URL'].'/assets/';#" "$CONFIGFILE.dist" > $CONFIGFILE

    cp "$CONF.dist" "$CONF" 

    # Setup mysql database
    echo "INSTALL DB"

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

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- apache2-foreground "$@"
fi

exec "$@"
