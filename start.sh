#!/bin/bash

RUN_MODE=$1
: ${RUN_MODE:="debug"}

echo "begin to start enclave runtime..."
./enclave.sh clean || true
./enclave.sh docker
./enclave.sh $RUN_MODE
echo "start enclave runtime completed"

echo "begin to start client..."
docker compose -f docker-compose-b.yaml down || true
docker compose -f docker-compose-b.yaml up -d
echo "start client completed"