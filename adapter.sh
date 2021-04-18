#!/bin/sh

if [ $1 = "run" ]; then
    docker run -d --network host --name adapter ${DOCKERHUB_ACCOUNT}/adapter:latest
fi