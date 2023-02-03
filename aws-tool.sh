#!/bin/sh

TAR_FILE_MODE="all"
SCRIPT_TAR="script.tar"
CLIENT_TAR="client.tar"
SINGLE_TAR="single.tar"

function tar_files() {
    SCRIPT_FILES="$SCRIPT_TAR *.sh *.yaml *.json .env"
    CLINET_FILES="$CLIENT_TAR client-runner client-app manifest.yaml genesis.json"

    if [ $TAR_FILE_MODE = "all" ]; then
        tar czf $SCRIPT_FILES
        tar czf $CLINET_FILES
    elif [ $TAR_FILE_MODE = "script" ]; then
        tar czf $SCRIPT_FILES
    elif [ $TAR_FILE_MODE = "client" ]; then
        tar czf $CLINET_FILES
    fi
}

function untar_files() {
    retval=""

    SCRIPT_FILES="tar xzf $SCRIPT_TAR"
    CLINET_FILES="tar xzf $CLIENT_TAR"

    if [ $TAR_FILE_MODE = "all" ]; then
        retval="$SCRIPT_FILES && $CLINET_FILES && rm $SCRIPT_TAR $CLIENT_TAR"
    elif [ $TAR_FILE_MODE = "script" ]; then
        retval="$SCRIPT_FILES && rm $SCRIPT_TAR"
    elif [ $TAR_FILE_MODE = "client" ]; then
        retval="$CLINET_FILES && rm $CLIENT_TAR"
    fi

    echo $retval
}

function scp_files() {
    retval=""

    if [ $TAR_FILE_MODE = "all" ]; then
        retval="$SCRIPT_TAR $CLIENT_TAR"
    elif [ $TAR_FILE_MODE = "script" ]; then
        retval="$SCRIPT_TAR"
    elif [ $TAR_FILE_MODE = "client" ]; then
        retval="$CLIENT_TAR"
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
        -L 5998:127.0.0.1:5998 \
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

function scp_libp2p_key() {
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    ssh -i "${PEM_PATH}" "ec2-user@${DNS_NAME}" "mkdir -p ~/.libp2p"
    scp -i "${PEM_PATH}" .conn_id_keys/${KEY_NAME}.key ec2-user@${DNS_NAME}:~/.libp2p/key
}

function scp_back() {
    : ${TARGET_PATH:=.}
    : ${PEM_PATH:="~/.ssh/aws-tea-northeast2.pem"}
    : ${DNS_NAME:=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`}

    scp -i "$PEM_PATH" ec2-user@${DNS_NAME}:${REMOTE_FILE} ${TARGET_PATH}
}

set -e

if [ $1 = "ids" ]; then
    aws ec2 describe-instances | jq '.Reservations[].Instances[] | "\(.InstanceId) \(.State.Name)"'
elif [ $1 = "dns" ]; then
    aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[] | "\(.Attachment.InstanceId) \(.Association.PublicDnsName) \(.Association.PublicIp)"'
elif [ $1 = "create" ]; then
    if [ -z "$4" ]; then
        aws ec2 run-instances --image-id ami-0c76973fbe0ee100c --count 1 --instance-type c5a.xlarge --key-name aws-tea-northeast2 --security-group-ids sg-a96a74d2 --enclave-options 'Enabled=true'
    else
        aws ec2 run-instances --image-id $2 --count 1 --instance-type c5a.xlarge --key-name $3 --security-group-ids $4 --enclave-options 'Enabled=true'
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
elif [ $1 = "libp2p" ]; then
    KEY_NAME=$2
    DNS_NAME=$3
    PEM_PATH=$4

    scp_libp2p_key

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
else
    echo "unknown command. Supported subcommand: ids, dns, create, terminate, ssh, push, install"
fi

set +e
