#/bin/bash

VAR_AVAIL=0
FILE=.env
if [ -f "$FILE" ]; then
   echo "$FILE exists so copy use contents as variables"
   source $FILE
   echo "$SERVICE"
   VAR_AVAIL=1
fi 

# input with eight arguments: go.sh SERVICE VERSION NETWORK PORT
if [ "$#" == 8 ]; then
   SERVICE=$1
   VAR_AVAIL=1
   VERSION=$2
   NETWORK=$3
   CANVAS_USER=$4
   CANVAS_PASSWORD=$5
   DBA_PASSWORD=$6
   HOST=$7
   DOMAIN=$8
fi


if [ $VAR_AVAIL = 1 ]; then 
   # make variables available 
   export SERVICE=$SERVICE
   export VERSION=$VERSION
   export NETWORK=$NETWORK
   export CANVAS_USER=$CANVAS_USER
   export CANVAS_PASSWORD=$CANVAS_PASSWORD
   export DBA_PASSWORD=$DBA_PASSWORD
   export HOST=$HOST
   export DOMAIN=$DOMAIN

   echo 'creating certificate based on wildcard created in LTI-SSL helper repository'

   if [[ ! -d ../certs ]]
   then
      echo "We need a ../certs folder to exist for this script run the LTI SSL helper repo and copy the results into ../certs"
      exit 1
   else
      if [[ ! -f ../certs/$DOMAIN.key ]]
      then
         echo "We need the wildcard key and certificate available in the ../certs folder"
         exit 1
      else
         if [[ ! -f ../certs/$HOST.key ]]
         then
            echo "private wildcard key doesn not exist. Let's create it for now"
            cp ../certs/$DOMAIN.key ../certs/$HOST.key
         fi
         if [[ ! -f ../certs/$HOST.crt ]]
         then
            echo  "private wildcard certificate doesn not exist. Let's create it for now"
            cp ../certs/$DOMAIN.crt ../certs/$HOST.crt
         fi
      fi
   f1

   echo 'stop full service'
   docker-compose down

   echo 'now start full service'
   docker-compose up -d

   echo 'adding local CA as certificate authotiry for testing... first wait for container to come up'
   sleep 10
   docker exec -u root $(docker ps --filter name=app -q) bash -c "update-ca-certificates > /dev/null 2>&1"

else
   echo "not enough variables available so not executing"
fi
# use method to clean logs periodically
# docker exec -it $(docker ps -aqf "name=canvas4edubadges_app_1") bash -c "> log/parallel-runtime-rspec.log; > log/production.log"
