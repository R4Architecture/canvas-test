# Docker Canvas for edubadges Testing 
-------------------------------
###### (This document is based on the UBC repo https://github.com/ubc/docker-canvas)


# Docker provisioning for Canvas integration tests (via LTI, etc)

Testing machines on edubadges use CentOS therefore building of Ubuntu docker images will not always work. This is caused by OverlayFS issues
https://docs.docker.com/storage/storagedriver/overlayfs-driver/

This imeplementation relies on certificates that need to be installed in certs folder. If you don't have access to official certificates (which is very likely for development you can create your own and use them as well as your own local domains) More information on this can be found here: https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/

or: https://medium.com/@superseb/get-your-certificate-chain-right-4b117a9c0fce
or: https://develike.com/en/articles/adding-a-trusted-self-signed-ssl-certificate-to-nginx-on-debian-ubuntu


## proxy information
If you, like me are running several subdomains to test you can use a proxy sollution. This implementation also uses a reverse proxy implementation of the "Jwilder Nginx Reverse Proxy" more information on this can be found at: 
https://blog.programster.org/jwilder-reverse-proxy-with-wildcard-ssl
 created in another repository to expose more than one test service over a docker machine
 If you are not using a proxy you should make the 443 port available in the docker-compose file

## Prerequisites

* [Docker Engine](https://docs.docker.com/engine/installation/)
* [Docker Compose](https://docs.docker.com/compose/install/)
* Large amount of memory allocated to your docker machine (Canvas uses a lot of memory). You need ~10GB to build the image and ~6GB to run the image.

# Setting Up

## Clone Repo

    git clone https://github.com/edubadges/canvas-image docker-canvas-image

## Generate Canvas Docker Image (with issues encountered on stable branch as of 2021-05-18)

Based on SHA `9ad21650ebbee144bd96a28aab53507a1bcefc6c`. Still working as of tag `release\2021-06-23.26`.

The official Canvas docker image might not be up-to-date with the version available on github. If you need an updated image, you will have to build it yourself. Check out Canvas from Instructure's github (make sure you're on the branch you need, e.g.: stable). *You will also need to copy the `Dockerfile.prod.with.fixes` file into the Canvas-lms repo* and run:

    docker build -t instructure/canvas-lms:stable -f Dockerfile.prod.with.fixes .

Note that Instructure recommends at around 10 GB of RAM to build this image. This will build and tag the image as a newer version in your docker cache.

Notes:
- There is currently no Dockerfile in Canvas that will generate an easily runnable image. `Dockerfile.prod.with.fixes` is a stopgap to getting a working version of Canvas running without dory/dinghy.
- It is a combination of Canvas repo's `Dockerfile` and `ubuntu.development.Dockerfile` files.
- `yarn install` needs the `--network-timeout 600000 --network-concurrency 1` options or it will fail.`


## After building the image the image can be transported to the centos environment using the docker save and docker load commands:

### regular save
    docker save -o canvas-lms-stable.tar instructure/canvas-lms:stable 

### or save with gzip
    docker save instructure/canvas-lms:stable | gzip > canvas-lms-stable.tar.gz

copy the file to the future host and load it

## load image

### regular load
    docker load --input canvas-lms-stable.tar 

### or load with gzip
    docker load < canvas-lms-stable.tar.gz


## If it is the first time running:

On host machine git clone https://github.com/edubadges/canvas-deploy docker-canvas

Either use script to generate the proces and secrets or work manually. Copy the example.env to .env and create your value pairs

### Automated initialization:
A script that will run the steps below in sequence with waits
    ./install_create.sh
This script either depends on 6! configuration values either to be present in an .env file or added as arguments to the command these are:

    ./install_create.sh <NETWORK_VALUE> <SERVICE_VALUE> <VERSION_VALUE> <CANVAS_PASSWORD_VALUE> <DBA_PASSWORD_VALUE> <HOST_VALUE> <DOMAIN_VALUE>

This script removes all previous docker images running with the label canvas

### Manual Initialization:
Load environment variables

    source .env

Initialize data by first starting the database:

    docker-compose up -d db

Wait a few moments for the database to start then (command might fail if database hasn't finished first time startup):

    docker-compose run --rm app bundle exec rake db:create db:initial_setup

When prompted enter default account email, password, and display name. Also choose to share usage data or not.

The branding assets must also be manually generated when canvas is in production mode:

    docker-compose run --rm app bundle exec rake canvas:compile_assets
    docker-compose run --rm app bundle exec rake brand_configs:generate_and_upload_all

Edit `/ect/hosts` and add the line:

    127.0.0.1 docker_canvas_app

Finally startup all the services:

    docker-compose up -d

Canvas is accessible 

    http://docker_canvas_app:8900/

MailHog (catches all out going mail from canvas) is accessible at

    http://localhost:8902/

# Running

## Start Server

If you haven't already load environment variables and then start docker-compose

    source .env
    docker-compose up -d

Or automated:

    ./go.sh

## Check Logs

    # app
    docker logs -f docker-canvas_app_1

    # more detailed app logs
    docker exec -it docker-canvas_app_1 tail -f log/production.log

    # worker
    docker logs -f docker-canvas_worker_1

    # db
    docker logs -f docker-canvas_db_1

    # redis
    docker logs -f docker-canvas_redis_1

    # mail
    docker logs -f docker-canvas_mail_1

## Stop Server

    docker-compose stop

## Stop Server and Clean Up

    docker-compose down
    rm -rf .data

## Update the DB

    docker compose run --rm app bundle exec rake db:migrate


# Environment Variable Configuration

## Passenger

`PASSENGER_STARTUP_TIMEOUT`: Increase to avoid first time startup Passenger timeout errors (can take a while and the timeout might be too short).

