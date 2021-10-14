#!/bin/sh

if [ $1 = "docker" ]; then
  if [ -z "$2" ]; then
    # docker rmi tearust/runtime:nitro
    docker rmi realraindust/runtime:latest
    # nitro-cli build-enclave --docker-uri tearust/runtime:nitro --output-file enclave_app.eif
    nitro-cli build-enclave --docker-uri realraindust/runtime:latest --output-file enclave_app.eif
  else
    docker rmi $2/runtime:nitro
    nitro-cli build-enclave --docker-uri $2/runtime:nitro --output-file enclave_app.eif
  fi
  echo "current docker images:"
  docker images
elif [ $1 = "debug" ]; then
  nitro-cli run-enclave --eif-path enclave_app.eif --cpu-count 2 --enclave-cid 6 --memory 1024 --debug-mode
elif [ $1 = "run" ]; then
  nitro-cli run-enclave --eif-path enclave_app.eif --cpu-count 2 --enclave-cid 6 --memory 1024
elif [ $1 = "list" ]; then
  nitro-cli describe-enclaves | jq
elif [ $1 = "clean" ]; then
  nitro-cli describe-enclaves | jq '.[0].EnclaveID' | xargs nitro-cli terminate-enclave --enclave-id
elif [ $1 = "console" ]; then
  nitro-cli describe-enclaves | jq '.[0].EnclaveID' | xargs nitro-cli console --enclave-id
else
  # todo print all available command later
  echo "unknown command. Supported subcommand: docker, debug, run, list, clean, console"
fi