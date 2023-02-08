#!/bin/sh

if [ $1 = "docker" ]; then
  DOCKER_USER=$2
  : ${DOCKER_USER:="tearust"}
  docker rmi $DOCKER_USER/runtime:nitro
  nitro-cli build-enclave --docker-uri $DOCKER_USER/runtime:nitro --output-file enclave_app.eif
  echo "current docker images:"
  docker images
elif [ $1 = "debug" ]; then
  nitro-cli run-enclave --eif-path enclave_app.eif --cpu-count 2 --enclave-cid 6 --memory 1024 --debug-mode
  nitro-cli describe-enclaves | jq '.[0].EnclaveID' | xargs nitro-cli console --enclave-id
elif [ $1 = "run" ]; then
  nitro-cli run-enclave --eif-path enclave_app.eif --cpu-count 2 --enclave-cid 6 --memory 1024
elif [ $1 = "list" ]; then
  nitro-cli describe-enclaves | jq
elif [ $1 = "clean" ]; then
  nitro-cli describe-enclaves | jq '.[0].EnclaveID' | xargs nitro-cli terminate-enclave --enclave-id
elif [ $1 = "console" ]; then
  nitro-cli describe-enclaves | jq '.[0].EnclaveID' | xargs nitro-cli console --enclave-id
elif [ $1 = "client" ]; then
  docker-compose down
  docker rmi tearust/parent-instance-client:nitro
  docker-compose up
elif [ $1 = "proxy" ]; then
  REGION=$2
  PORT=$3
  : ${REGION:="ap-northeast-2"}
  : ${PORT:="8001"}
  vsock-proxy $PORT kms.$REGION.amazonaws.com 443
else
  echo "unknown command. Supported subcommand: docker, debug, run, list, clean, console, client, proxy"
fi