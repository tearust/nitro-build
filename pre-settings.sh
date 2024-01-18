#!/bin/bash

TEA_ID=$1
MACHINE_OWNER=$2
STARTUP_PROOF=$3
: ${TEA_ID:=""}
: ${MACHINE_OWNER:=""}

confirm_tea_id() {
  echo "please enter your tea id...(hex encoded, ie. 0x0000000000000000000000000000000000000000000000000000000000000000)"
  set +e
  read -r TEA_ID </dev/tty
  rc=$?
  set -e

  if [[ $TEA_ID =~ ^(0x)*[[:xdigit:]]{64}$ ]]; then
    echo "tea id accepted" 
  else
    error "Error reading from prompt (please re-run to type tea id)"
    exit 1
  fi
}

confirm_machine_owner() {
  echo "please enter your machine owner layer1 account address...(ie. 0xbd6D4f56b59e45ed25c52Eab7EFf2c626e083db9)"
  set +e
  read -r MACHINE_OWNER </dev/tty
  rc=$?
  set -e

  if [[ $MACHINE_OWNER =~ ^(0x)*[[:xdigit:]]{40}$ ]]; then
    echo "machine id owner accepted" 
  else
    error "Error reading from prompt (please re-run to type machine owner)"
    exit 1
  fi
}

confirm_startup_proof() {
  echo "please enter your startup proof..."

  read -r STARTUP_PROOF </dev/tty

  echo "aws region accepted" 
}

set -e
sudo yum -y install git || true

echo "begin to git clone resources..."
RESOURCE_DIR=$HOME/nitro-build
if [ ! -d "$RESOURCE_DIR" ]; then
	git clone -b main https://github.com/tearust/nitro-build
	cd $RESOURCE_DIR
else
	cd $RESOURCE_DIR

  git fetch origin
	git reset --hard origin/main
fi
echo "clone resources completed"

source server.env
ENV_FILE=$RESOURCE_DIR/.env

if [[ -n "$TEA_ID" && -n "$MACHINE_OWNER" && -n "$LIBP2P_BOOTNODES" && -n "$NITRO_KEY_ID" ]]; then
  echo "begin to init env file through command line arguments"
  printf "TEA_ID=$TEA_ID\nMACHINE_OWNER=$MACHINE_OWNER\nLIBP2P_BOOTNODES=$LIBP2P_BOOTNODES\nNITRO_KEY_ID=$NITRO_KEY_ID\nSTARTUP_PROOF=$STARTUP_PROOF\n" > $ENV_FILE
else
  if [ ! -f "$ENV_FILE" ]; then
    echo "begin to init env file from prompt"

    confirm_tea_id
    echo "TEA_ID=$TEA_ID" > $ENV_FILE

    confirm_machine_owner
    echo "MACHINE_OWNER=$MACHINE_OWNER" >> $ENV_FILE

    echo "LIBP2P_BOOTNODES=$LIBP2P_BOOTNODES\nNITRO_KEY_ID=$NITRO_KEY_ID\n" >> $ENV_FILE

    confirm_startup_proof
    echo "STARTUP_PROOF=$STARTUP_PROOF" >> $ENV_FILE

	echo ""
  fi
fi
