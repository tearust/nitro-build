#!/bin/bash

TEA_ID=$1
MACHINE_OWNER=$2
AWS_REGION=$3
STARTUP_PROOF=$4
RUN_MODE=$5
: ${TEA_ID:=""}
: ${MACHINE_OWNER:=""}
: ${AWS_REGION:=""}
: ${STARTUP_PROOF:=""}
: ${RUN_MODE:="run"}

set -e

echo "begin to pre settings..."
./pre-settings.sh $TEA_ID $MACHINE_OWNER $AWS_REGION $STARTUP_PROOF
echo "pre settings completed"

echo "begin to start enclave runtime..."
./enclave.sh clean || true
./enclave.sh docker
./enclave.sh $RUN_MODE
echo "start enclave runtime completed"

echo "begin to start client..."
docker-compose -f docker-compose-b.yaml down
docker rmi tearust/parent-instance-client:alpha-1.6
docker-compose -f docker-compose-b.yaml up -d
echo "start client completed"