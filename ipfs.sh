#!/bin/sh

DOCKERHUB_ACCOUNT=$2
: ${DOCKERHUB_ACCOUNT:="tearust"}

cd ipfs

set -e
if [ $1 = "compile" ]; then
    if [ ! -d "go-ipfs" ] ; then
        git clone https://github.com/ipfs/go-ipfs.git --branch v0.8.0 --single-branch --depth 1
    fi
    cd go-ipfs

    echo "compile for native"
    make build
    cp cmd/ipfs/ipfs ..

    echo "compile for docker"
    make build GOOS=linux GOARCH=amd64
    cp cmd/ipfs/ipfs ../ipfs-linux

    cd ..
elif [ $1 = "build" ]; then
    # prepare folder and file
    rm -rf docker
    mkdir -p docker/ipfs
    cd docker/ipfs
    # make sure you have run the `compile` subcommand or copied ipfs exe somewhere else
    cp ../../ipfs .
    
    # prepare ipfs related
    export IPFS_PATH=$PWD
    ./ipfs init
    ./ipfs bootstrap rm --all
    cp ../../swarm.key .

    # add data to ipfs
    CIDS_FILE="../../../cids.txt"
    if [ -d "$CIDS_FILE" ] ; then
        rm $CIDS_FILE
    fi
    echo "tea_ra_signed.wasm" > $CIDS_FILE
    CID=`./ipfs block put ../../../tea_ra_signed.wasm`
    echo "$CID" >> $CIDS_FILE
    echo "tea_ra.binding.json" >> $CIDS_FILE
    CID=`./ipfs block put ../../../tea_ra.binding.json`
    echo "$CID" >> $CIDS_FILE

    # build ipfs docker image
    cd ..
    cp ../Dockerfile .
    cp ../ipfs-linux ipfs/ipfs # replace ipfs exe
    docker build --tag ${DOCKERHUB_ACCOUNT}/ipfs:0.8.0 .
    docker push ${DOCKERHUB_ACCOUNT}/ipfs:0.8.0

    cd ..
elif [ $1 = "run" ]; then
    docker run -d --network host --name ipfs ${DOCKERHUB_ACCOUNT}/ipfs:0.8.0
fi

set +e

cd ..