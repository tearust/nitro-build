#!/bin/sh

TAR_FILE_MODE="all"
SCRIPT_TAR="script.tar"
CLIENT_TAR="client.tar"
VMH_TAR="vmh.tar"
SINGLE_TAR="single.tar"

function tar_files() {
    SCRIPT_FILES="$SCRIPT_TAR *.sh *.yaml swarm.key"
    CLINET_FILES="$CLIENT_TAR parent-instance-client provider_kvp provider_nitro provider_crypto actor_utility_ipfs actor_utility_rpc_adapter actor_utility_rpc_layer1"
    VMH_FILES="$VMH_TAR vmh-server"

    if [ $TAR_FILE_MODE = "all" ]; then
        tar czf $SCRIPT_FILES
        tar czf $CLINET_FILES
        tar czf $VMH_FILES
    elif [ $TAR_FILE_MODE = "script" ]; then
        tar czf $SCRIPT_FILES
    elif [ $TAR_FILE_MODE = "client" ]; then
        tar czf $CLINET_FILES
    elif [ $TAR_FILE_MODE = "vmh" ]; then
        tar czf $VMH_FILES
    fi
}

function untar_files() {
    retval=""

    SCRIPT_FILES="tar xzf $SCRIPT_TAR"
    CLINET_FILES="tar xzf $CLIENT_TAR"
    VMH_FILES="tar xzf $VMH_TAR"

    if [ $TAR_FILE_MODE = "all" ]; then
        retval="$SCRIPT_FILES && $CLINET_FILES && $VMH_FILES && rm $SCRIPT_TAR $CLIENT_TAR $VMH_TAR"
    elif [ $TAR_FILE_MODE = "script" ]; then
        retval="$SCRIPT_FILES && rm $SCRIPT_TAR"
    elif [ $TAR_FILE_MODE = "client" ]; then
        retval="$CLINET_FILES && rm $CLIENT_TAR"
    elif [ $TAR_FILE_MODE = "vmh" ]; then
        retval="$VMH_FILES && rm $VMH_TAR"
    fi

    echo $retval
}

function scp_files() {
    retval=""

    if [ $TAR_FILE_MODE = "all" ]; then
        retval="$SCRIPT_TAR $CLIENT_TAR $VMH_TAR"
    elif [ $TAR_FILE_MODE = "script" ]; then
        retval="$SCRIPT_TAR"
    elif [ $TAR_FILE_MODE = "client" ]; then
        retval="$CLIENT_TAR"
    elif [ $TAR_FILE_MODE = "vmh" ]; then
        retval="$VMH_TAR"
    fi

    echo $retval
}

function ssh_with() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}
    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" $SSH_CMD
}

function tunnel_with() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}
    ssh -i "${PEM_PATH}" \
        -L 8000:127.0.0.1:8000 \
        -L 9944:127.0.0.1:9944 \
        -L 5001:127.0.0.1:5001 \
        -L 5010:127.0.0.1:5010 \
        -L 5011:127.0.0.1:5011 \
        -L 5012:127.0.0.1:5012 \
        -L 5013:127.0.0.1:5013 \
        -N -T "ec2-user@${DNS_NAME}"
}

function scp_with() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    scp -i "$PEM_PATH" `scp_files` ec2-user@${DNS_NAME}:~
}

function scp_single() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    tar czf ${SINGLE_TAR} ${SINGLE_FILE}
    scp -i "${PEM_PATH}" ${SINGLE_TAR} ec2-user@${DNS_NAME}:~
    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "tar xzf ${SINGLE_TAR}"
}

function scp_back() {
    : ${TARGET_PATH:=.}
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    scp -i "$PEM_PATH" ec2-user@${DNS_NAME}:${REMOTE_FILE} ${TARGET_PATH}
}

function ipfs_init() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "rm -rf .ipfs && mkdir -p .ipfs && cp swarm.key .ipfs/"
}

function ipfs_id() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "docker exec ipfs ipfs id | jq -r '.ID'"
}

function ipfs_bootstrap_clear() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "docker exec ipfs ipfs bootstrap rm --all"
}

function ipfs_bootstrap_add() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "docker exec ipfs ipfs bootstrap add ${IPFS_ADDRESS}"
}

function ipfs_bootstrap_list() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "docker exec ipfs ipfs bootstrap list"
}

function ipfs_swarm_peers() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "docker exec ipfs ipfs swarm peers"
}

set -e

if [ $1 = "ids" ]; then
    aws ec2 describe-instances | jq '.Reservations[].Instances[] | "\(.InstanceId) \(.State.Name)"'
elif [ $1 = "dns" ]; then
    aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[] | "\(.Attachment.InstanceId) \(.Association.PublicDnsName) \(.Association.PublicIp)"'
elif [ $1 = "create" ]; then
    if [ -z "$4" ]; then
        aws ec2 run-instances --image-id ami-07464b2b9929898f8 --count 1 --instance-type c5.xlarge --key-name aws-tea-northeast2 --security-group-ids sg-a96a74d2 --enclave-options 'Enabled=true'
    else
        aws ec2 run-instances --image-id $2 --count 1 --instance-type c5.xlarge --key-name $3 --security-group-ids $4 --enclave-options 'Enabled=true'
    fi
elif [ $1 = "terminate" ]; then
    if [ -z "$2" ]; then
        aws ec2 describe-instances | jq '.Reservations[0].Instances[0].InstanceId' | xargs aws ec2 terminate-instances --instance-ids
    else
        aws ec2 terminate-instances --instance-ids $2
    fi
elif [ $1 = "ssh" ]; then
    DNS_NAME=$2
    PEM_PATH=$3

    SSH_CMD=""
    ssh_with
elif [ $1 = "tunnel" ]; then
    DNS_NAME=$2
    PEM_PATH=$3

    tunnel_with
elif [ $1 = "push" ]; then
    TAR_FILE_MODE=$2
    DNS_NAME=$3
    PEM_PATH=$4
    : ${TAR_FILE_MODE:="all"}

    SSH_CMD=$( untar_files )

    tar_files
    scp_with
    ssh_with

    echo "done!"
elif [ $1 = "single" ]; then
    SINGLE_FILE=$2
    DNS_NAME=$3
    PEM_PATH=$4

    scp_single

    echo "done!"
elif [ $1 = "install" ]; then
    DNS_NAME=$2
    PEM_PATH=$3

    SSH_CMD="sh ./aws-prepare.sh"
    ssh_with

    echo "done!"
elif [ $1 = "scp" ]; then
    REMOTE_FILE=$2
    TARGET_PATH=$3
    DNS_NAME=$4
    PEM_PATH=$5

    scp_back

    echo "done!"
elif [ $1 = "ipfs" ]; then
    if [ $2 = "init" ]; then
        DNS_NAME=$3
        PEM_PATH=$4

        ipfs_init
    elif [ $2 = "id" ]; then
        DNS_NAME=$3
        PEM_PATH=$4

        ipfs_id
    elif [ $2 = "clear" ]; then
        DNS_NAME=$3
        PEM_PATH=$4

        ipfs_bootstrap_clear
    elif [ $2 = "bootstrap" ]; then
        DNS_NAME=$3
        PEM_PATH=$4

        ipfs_bootstrap_list
    elif [ $2 = "add" ]; then
        IPFS_ADDRESS=$3
        DNS_NAME=$4
        PEM_PATH=$5

        ipfs_bootstrap_add
    elif [ $2 = "peers" ]; then
        DNS_NAME=$3
        PEM_PATH=$4

        ipfs_swarm_peers
    else
        echo "unknown ipfs sub-command. Supported subcommand: id, clear, add, peers"
    fi
else
    echo "unknown command. Supported subcommand: ids, dns, create, terminate, ssh, push, install"
fi

set +e