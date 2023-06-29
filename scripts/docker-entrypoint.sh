#!/bin/bash

if [ "$1" = "rstudio" ]
then
    echo "---> Waiting for the Postgres DB to become available ..."
    until 2>/dev/null >/dev/tcp/postgres/5432
    do
        echo "-- postgres is not available.  Sleeping ..."
        sleep 2
    done

    echo "---> Activating the RSW License ..."
    /usr/lib/rstudio-server/bin/license-manager activate $RSP_LICENSE

    echo "---> Starting Launcher ..."
    /usr/bin/rstudio-launcher start
    sleep 4
 
    echo "---> Starting Server ..."
    /usr/sbin/rstudio-server start
    sleep 4 

    while true 
    do
        sleep 20
    done

fi


exec "$@"


