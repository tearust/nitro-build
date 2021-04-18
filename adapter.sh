#!/bin/sh

DOCKERHUB_ACCOUNT=$2
: ${DOCKERHUB_ACCOUNT:="tearust"}

if [ $1 = "run" ]; then
    docker run -d --network host --name adapter ${DOCKERHUB_ACCOUNT}/adapter:latest
fi