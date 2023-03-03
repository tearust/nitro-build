#!/bin/sh

if [ -n $1 ] && [ $1 = "rm" ]; then
	docker rmi tearust/parent-instance-client:nitro-cli
fi

source ~/.env

docker run \
  --name client \
  --network host \
  --rm \
  -v `pwd`/.log:/log \
  -v `pwd`/.tokenstate:/tokenstate \
  -v `pwd`/.libp2p:/libp2p	\
  -v `pwd`/.layer1:/layer1 \
  -v `pwd`/genesis.json:/tearust/data/genesis.json \
  -e ENCLAVE_CID=6 \
  -e LOG_FILE=/log/output.log \
  -e GENESIS_CONFIG_PATH=/tearust/data/genesis.json \
  -e LAYER1_WS_PROVIDER_URL=${LAYER1_WS_PROVIDER_URL} \
  -e LAYER1_KEY_PATH=/layer1/key \
  -e TEA_ID="${TEA_ID}" \
  -e MACHINE_OWNER="${MACHINE_OWNER}" \
  -e LIBP2P_NODE_KEY_PATH=/libp2p/key \
  -e LIBP2P_VERSION="nitro0.1" \
  -e IP_ADDRESS=${IP_ADDRESS} \
  -e LIBP2P_BOOTNODES=${LIBP2P_BOOTNODES} \
  -e LIBP2P_ENABLE_RELAY_PEERS="true" \
  -e APPLY_VALIDATOR="true" \
  -e STATE_MAGIC_NUMBER=200 \
  -e PERSIST_PATH=/tokenstate/persist \
  -e RUST_BACKTRACE=full \
  --log-opt max-size=20m \
  --log-opt max-file=5  \
  -it tearust/parent-instance-client:nitro-cli /bin/bash
