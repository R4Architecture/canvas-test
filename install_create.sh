#/bin/bash

VAR_AVAIL=0
FILE=.env
if [ -f "$FILE" ]; then
   echo "$FILE exists so copy use contents as variables"
   source $FILE
   echo "$SERVICE"
   VAR_AVAIL=1
fi 

# input with four arguments: go.sh SERVICE VERSION NETWORK PORT
if [ "$1" != "" ]; then
        SERVICE=$1
        VAR_AVAIL=1
fi
if [ "$2" != "" ]; then
        VERSION=$2
fi
if [ "$3" != "" ]; then
        NETWORK=$3
fi
if [ "$4" != "" ]; then
        CANVAS_USER=$4
fi
if [ "$5" != "" ]; then
        CANVAS_PASSWORD=$5
fi
if [ "$6" != "" ]; then
         DBA_PASSWORD=$6
fi
if [ "$7" != "" ]; then
        HOST=$7
fi
if [ "$8" != "" ]; then
        DOMAIN=$8
fi


if [ $VAR_AVAIL == 1 ] 
then 
        # make variables available 
        export SERVICE=$SERVICE
        export VERSION=$VERSION
        export NETWORK=$NETWORK
        export CANVAS_USER=$CANVAS_USER
        export CANVAS_PASSWORD=$CANVAS_PASSWORD
        export DBA_PASSWORD=$DBA_PASSWORD
        export HOST=$HOST
        export DOMAIN=$DOMAIN

        # create network
        docker network create $NETWORK

        # prepare go
        # preparations are only needed for full new install
        ./prepare.sh
else
        echo 'not enough variables available so not executing'
fi