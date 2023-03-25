#!/bin/bash

TEA_ID=$1
MACHINE_OWNER=$2
AWS_REGION=$3
: ${TEA_ID:=""}
: ${MACHINE_OWNER:=""}
: ${AWS_REGION:=""}

set -e

echo "begin to pre settings..."
./pre-settings.sh $TEA_ID $MACHINE_OWNER $AWS_REGION
echo "pre settings completed"

echo "begin to install dependencies..."
./aws-prepare.sh
echo "install dependencies completed"

newgrp docker
