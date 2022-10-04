#!/bin/sh

if [ -n $1 ] && [ $1 = "rm" ]; then
	docker rmi tearust/parent-instance-client:nitro-cli
fi

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
  -e LAYER1_WS_PROVIDER_URL=wss://goerli.infura.io/ws/v3/4926c6c0569842b89fb5df97a537e198 \
  -e LAYER1_KEY_PATH=/layer1/key \
	-e TEA_ID="0xdf38cb4f12479041c8e8d238109ef2a150b017f382206e24fee932e637c2db7b" \
	-e MACHINE_OWNER="0x754d7b24d8a4ec00000000000000000000000000" \
	-e LIBP2P_NODE_KEY_PATH=/libp2p/key \
	-e LIBP2P_VERSION="local0.1" \
	-e IP_ADDRESS=127.0.0.1 \
	-e APPLY_VALIDATOR="true" \
	-e STATE_MAGIC_NUMBER=100 \
	-e PERSIST_PATH=/tokenstate/persist \
	-e RUST_BACKTRACE=full \
	-it tearust/parent-instance-client:nitro-cli /bin/bash
