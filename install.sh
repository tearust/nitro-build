#!/bin/bash

TEA_ID=$1
MACHINE_OWNER=$2
AWS_REGION=$3
RUN_MODE=$4
: ${TEA_ID:=""}
: ${MACHINE_OWNER:=""}
: ${AWS_REGION:=""}
: ${RUN_MODE:="debug"}

info() {
  printf '%s\n' "${BOLD}${GREY}>${NO_COLOR} $*"
}

warn() {
  printf '%s\n' "${YELLOW}! $*${NO_COLOR}"
}

error() {
  printf '%s\n' "${RED}x $*${NO_COLOR}" >&2
}

completed() {
  printf '%s\n' "${GREEN}✓${NO_COLOR} $*"
}

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

confirm_aws_region() {
  echo "please enter your aws ec2 instance located region...(ie. ap-northeast-2)"

  read -r AWS_REGION </dev/tty

  echo "aws region accepted" 
}

pre_settings() {
	sudo apt-get install -y git

  info "begin to git clone resources..."
  RESOURCE_DIR=$HOME/nitro-build
  if [ ! -d "$RESOURCE_DIR" ]; then
  	git clone -b main https://github.com/tearust/nitro-build
  	cd $RESOURCE_DIR
  else
  	cd $RESOURCE_DIR

    git fetch origin
  	git reset --hard origin/main
  fi
  completed "clone resources completed"

	source server.env
  ENV_FILE=$RESOURCE_DIR/.env

  if [[ -n "$TEA_ID" && -n "$MACHINE_OWNER" && -n "$AWS_REGION" && -n "$LIBP2P_BOOTNODES" && -n "$NITRO_KEY_ID" ]]; then
    info "begin to init env file through command line arguments"
    printf "TEA_ID=$TEA_ID\nMACHINE_OWNER=$MACHINE_OWNER\nAWS_REGION=$AWS_REGION\nLIBP2P_BOOTNODES=$LIBP2P_BOOTNODES\nNITRO_KEY_ID=$NITRO_KEY_ID\n" > $ENV_FILE
  else
    if [ ! -f "$ENV_FILE" ]; then
      info "begin to init env file from prompt"

      confirm_tea_id
      echo "TEA_ID=$TEA_ID" > $ENV_FILE

      confirm_machine_owner
      echo "MACHINE_OWNER=$MACHINE_OWNER" >> $ENV_FILE

			confirm_aws_region
      echo "AWS_REGION=$AWS_REGION\nLIBP2P_BOOTNODES=$LIBP2P_BOOTNODES\nNITRO_KEY_ID=$NITRO_KEY_ID\n" >> $ENV_FILE

			echo ""
    fi
  fi
}

set -eu

sudo yum -y install git || true

info "begin to pre settings..."
pre_settings
completed "pre settings completed"

info "begin to install dependencies..."
./aws-prepare.sh
completed "install dependencies completed"

info "begin to start enclave runtime..."
./enclave.sh clean || true
./enclave.sh docker
./enclave.sh $RUN_MODE
completed "start enclave runtime completed"

info "begin to start client..."
sudo docker compose -f docker-compose-b.yaml down || true
sudo docker compose -f docker-compose-b.yaml up -d
completed "start client completed"