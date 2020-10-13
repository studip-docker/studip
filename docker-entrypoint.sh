#!/bin/bash
set -e

STUDIP='/var/www/studip/'
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
        /\$DB_STUDIP_DATABASE/ s/\"studip\"/\"${MYSQL_DATABASE}\"/" "$CONFIGFILE.dist" > $CONFIGFILE

    cp "$CONF.dist" "$CONF" 

    # Setup mysql database
    echo "INSTALL DB"
    mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}db/studip.sql
    echo "INSTALL DEFAULT DATA"
    mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}db/studip_default_data.sql
    mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}db/studip_resources_default_data.sql

    echo "INSTALL ROOTUSER"
    mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}db/studip_root_user.sql

    echo "INSTALL DEMODATA"
    mysql -u $MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD $MYSQL_DATABASE < ${STUDIP}db/studip_demo_data.sql


fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- apache2-foreground "$@"
fi

exec "$@"
