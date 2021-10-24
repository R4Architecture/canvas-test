#!/bin/bash

# delete previous version
# note: geen rollback!
#docker-compose -f docker-compose.init.yml down --rmi all
#echo "removing old images... wait 20 seconds"

#sleep 20
echo "stop (and if needed remove old) containers and volumes wait 5 seconds"
docker stop $(docker ps -a -q)
docker rm -f $(docker ps -a -q)
sleep 5
echo "removing old volumes ... wait 5 seconds"
docker volume rm $(docker volume ls --filter "label=canvas" -q)
sleep 5
echo "stop and remove old containers and volumes succesful!"
docker ps -a
docker volume ls

#create two run once services for initialisation purposes
#disabled so database does not gets rebuilt
function full_build(){

    # create a volume that will be used across all tests
    docker volume create postgresdata --label=canvas
    docker volume create canvas_css_data --label=canvas
    docker volume create canvas_tmp_data --label=canvas
    docker volume create redisdata --label=canvas
    echo "create volumes successful!"

    #echo "load canvas.tar"
    #docker load --input canvas-lms-stable.tar

    #set secret in yml file and in secrets file for docker
    secret=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 40 | head -n 1)
    #start with empty security.yml
    FILE=deploy/security.yml_org
    if [ -f "$FILE" ]; then
        echo "$FILE exists so copy contents"
        cp ./deploy/security.yml_org ./deploy/conf/security.yml
    else 
        echo "$FILE does not exist"
    fi
    sed "s/12345/$secret/g" ./deploy/conf/security.yml > ./deploy/sec_test.yml
    cp ./deploy/sec_test.yml ./deploy/conf/security.yml
    echo 'clean up temp secret file'
    rm ./deploy/sec_test.yml
    #echo "$secret" | docker secret create $COMPOSE_SECRET -
    export COMPOSE_SECRET=$secret
    echo 'new api secret:' $COMPOSE_SECRET
    echo $COMPOSE_SECRET > ./deploy/secret.txt

    # create developer API key
    api_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
    #echo "$api_key" | docker secret create $COMPOSE_API_KEY -
    export COMPOSE_API_KEY=$api_key
    echo 'new api-key:' $COMPOSE_API_KEY
    echo $COMPOSE_API_KEY > ./deploy/api_key.txt

    echo 'current dba password:' $DBA_PASSWORD
    echo $DBA_PASSWORD > ./deploy/dba_password.txt

    echo 'first_run_build'
    docker-compose up -d canvas-db
    # TODO automatic create of keys in data base

    sleep 10
    echo "let's wait 10 seconds for db to start"
    CANVAS_RAILS5_2=1 docker-compose run --rm app bundle exec rake db:create db:initial_setup
    #for debugging of a container 
    #docker-compose run --rm app bundle exec tail -f COPYRIGHT
    echo 'initial_setup succes!'
    docker-compose run --rm app bundle exec rake canvas:compile_assets
    echo 'compile _assets done!'
    docker-compose run --rm app bundle exec rake brand_configs:generate_and_upload_all
    echo 'generate_and_upload done!'

    echo 'optional next code to add and enable development keys/uncomment if needed'

    # crypt=$(echo -n $api_key | openssl sha1 -hmac $secret -binary | xxd -p)
    # crypt=$(echo -n $COMPOSE_API_KEY | openssl sha1 -hmac  $COMPOSE_SECRET -binary | xxd -p)
    # echo $crypt
    # docker-compose run --rm -e PGPASSWORD=$DBA_PASSWORD canvas-db psql -h canvas-db -U canvas -d canvas -c "INSERT INTO developer_keys (api_key, root_account_id, email, created_at, updated_at, name, redirect_uri) VALUES ('$api_key' , 1 , '$CANVAS_USER', now(), now(), 'Canvas API 4 $DOMAIN', 'https://$HOST');"

    # # 'crypted_token' value is hmac sha1 of 'canvas-docker' using default config/security.yml encryption_key value as secret
    # docker-compose run --rm -e PGPASSWORD=$DBA_PASSWORD canvas-db psql -h canvas-db -U canvas -d canvas -c "INSERT INTO access_tokens (created_at, crypted_token, root_account_id, developer_key_id, purpose, token_hint, updated_at, user_id) SELECT now(), '$crypt', 1, dk.id, 'general_developer_key', '', now(), 1 FROM developer_keys dk where dk.email = '$CANVAS_USER';"

    # #sleep 10
    # # need to activate the token 
    # docker-compose run --rm -e PGPASSWORD=$DBA_PASSWORD canvas-db psql -h canvas-db -U canvas -d canvas -c  "update developer_key_account_bindings set workflow_state = 'on' where account_id = 2 and developer_key_id = (select id FROM developer_keys dk where dk.email = '$CANVAS_USER');"

    # # echo 'test if database updates have taken place' 
    # docker-compose run --rm -e PGPASSWORD=$DBA_PASSWORD canvas-db psql -h canvas-db -U canvas -d canvas -c  "SELECT * FROM access_tokens;"
    # docker-compose run --rm -e PGPASSWORD=$DBA_PASSWORD canvas-db psql -h canvas-db -U canvas -d canvas -c  "SELECT * FROM developer_keys;"
    # docker-compose run --rm -e PGPASSWORD=$DBA_PASSWORD canvas-db psql -h canvas-db -U canvas -d canvas -c  "SELECT * FROM developer_key_account_bindings;"

    #info in canvas for creating key
    #https://github.com/instructure/canvas-lms/blob/88fae607ae7c386912992062990a6c405d6d76ab/lib/canvas/security.rb
    #https://github.com/instructure/canvas-lms/blob/a664cdb0b26bf9d4473c0204dba38fc73a34ece7/lib/canvas/security/services_jwt.rb


    echo 'now start full service'
    docker-compose up -d

    
    echo 'adding local CA as certificate authotiry for testing... first wait for container to come up'
    sleep 10
    docker exec -u root $(docker ps --filter name=app -q) bash -c "update-ca-certificates > /dev/null 2>&1"
}

#if fullbuild needed uncomment this
full_build