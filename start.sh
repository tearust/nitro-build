#!/bin/bash

TEA_ID=$1
MACHINE_OWNER=$2
AWS_REGION=$3
RUN_MODE=$4
: ${TEA_ID:=""}
: ${MACHINE_OWNER:=""}
: ${AWS_REGION:=""}
: ${RUN_MODE:="run"}

set -e

echo "begin to pre settings..."
./pre-settings.sh $TEA_ID $MACHINE_OWNER $AWS_REGION
echo "pre settings completed"

echo "begin to start enclave runtime..."
./enclave.sh clean || true
./enclave.sh docker
./enclave.sh $RUN_MODE
echo "start enclave runtime completed"

echo "begin to start client..."
docker-compose -f docker-compose-b.yaml down
docker-compose -f docker-compose-b.yaml up -d
echo "start client completed"