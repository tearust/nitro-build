#!/bin/sh

set +x
docker run -d --network host ipfs/go-ipfs:v0.7.0 daemon
set -x