<?php
/*basic settings for Stud.IP
----------------------------------------------------------------
you find here the basic system settings. You shouldn't have to touch much of them...
please note the CONFIG.INC.PHP for the indivual settings of your installation!*/

namespace Studip {
    //const ENV = 'development';
    define ('ENV', getenv('ENV') ?? 'development');
}

namespace {
    /*settings for database access
    ----------------------------------------------------------------
    please fill in your database connection settings.
    */

    // default Stud.IP database (DB_Seminar)
    $DB_STUDIP_HOST = getenv('MYSQL_HOST');
    $DB_STUDIP_USER = getenv('MYSQL_USER');
    $DB_STUDIP_PASSWORD = getenv('MYSQL_PASSWORD');
    $DB_STUDIP_DATABASE = getenv('MYSQL_DATABASE');

    /*URL
    ----------------------------------------------------------------
    customize if automatic detection fails, e.g. when installation is hidden
    behind a proxy
    */
    //$CANONICAL_RELATIVE_PATH_STUDIP = '/';
    //$ABSOLUTE_URI_STUDIP = 'https://www.studip.de/';
    //$ASSETS_URL = 'https://www.studip.de/assets/';

    // Set proxy url
    if ($PROXY_URL = getenv('PROXY_URL')) {
        $ABSOLUTE_URI_STUDIP = $PROXY_URL;
        $ASSETS_URL = $PROXY_URL.'/assets/';
        unset($PROXY_URL);
    }

    // Use autoproxy
    if (getenv('AUTO_PROXY')) {
        $ABSOLUTE_URI_STUDIP = $_SERVER['HTTP_X_FORWARDED_PROTO'].'://'.$_SERVER['HTTP_X_FORWARDED_HOST'].'/';
        $ASSETS_URL = $ABSOLUTE_URI_STUDIP.'/assets/';
    }
}