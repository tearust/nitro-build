#!/bin/sh

TAR_FILE_MODE="all"
SCRIPT_TAR="script.tar"
CLIENT_TAR="client.tar"
VMH_TAR="vmh.tar"

function tar_files() {
    SCRIPT_FILES="$SCRIPT_TAR *.sh *.yaml"
    CLINET_FILES="$CLIENT_TAR parent-instance-client provider_kvp actor_utility_ipfs"
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

if [ $1 = "ids" ]; then
    aws ec2 describe-instances | jq '.Reservations[].Instances[] | "\(.InstanceId) \(.State.Name)"'
elif [ $1 = "dns" ]; then
    aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[] | "\(.Attachment.InstanceId) \(.Association.PublicDnsName)"'
elif [ $1 = "create" ]; then
    if [ -z "$4" ]; then
        aws ec2 run-instances --image-id ami-07464b2b9929898f8 --count 1 --instance-type c5.xlarge --key-name aws-tea-northeast2 --security-group-ids sg-a96a74d2 --enclave-options 'Enabled=true'
    else
        aws ec2 run-instances --image-id $2 --count 1 --instance-type c5.xlarge --key-name $3 --security-group-ids $4 --enclave-options 'Enabled=true'
    fi
elif [ $1 = "terminate" ]; then
    set +x
    if [ -z "$2" ]; then
        aws ec2 describe-instances | jq '.Reservations[0].Instances[0].InstanceId' | xargs aws ec2 terminate-instances --instance-ids
    else
        aws ec2 terminate-instances --instance-ids $2
    fi
    set -x
elif [ $1 = "ssh" ]; then
    set +x
    DNS_NAME=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`
    if [ -n "$3" ]; then
        ssh -i "$2" ec2-user@$3
    elif [ -n "$2" ]; then
        ssh -i "$2" ec2-user@${DNS_NAME}
    else
        ssh -i "~/.ssh/aws-tea-northeast2.pem" "ec2-user@${DNS_NAME}"
    fi
    set -x
elif [ $1 = "push" ]; then
    tar_files
    TAR_FILE_MODE=$3
    : ${TAR_FILE_MODE:="all"}

    DNS_NAME=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`
    SSH_CMD=$( untar_files )
    if [ -n "$4" ]; then
        scp -i "$2" `scp_files` ec2-user@$4:~
        ssh -i "$2" ec2-user@$4 "$SSH_CMD"
    elif [ -n "$2" ]; then
        scp -i "$2" `scp_files` ec2-user@${DNS_NAME}:~
        ssh -i "$2" ec2-user@${DNS_NAME} "$SSH_CMD"
    else
        scp -i "~/.ssh/aws-tea-northeast2.pem" `scp_files` "ec2-user@${DNS_NAME}":~
        ssh -i "~/.ssh/aws-tea-northeast2.pem" "ec2-user@${DNS_NAME}" "$SSH_CMD"
    fi
elif [ $1 = "install" ]; then
    DNS_NAME=`aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'`
    SSH_CMD="sh ./aws-prepare.sh"
    if [ -n "$3" ]; then
        ssh -i "$2" ec2-user@$3 $SSH_CMD
    elif [ -n "$2" ]; then
        ssh -i "$2" ec2-user@${DNS_NAME} $SSH_CMD
    else
        ssh -i "~/.ssh/aws-tea-northeast2.pem" "ec2-user@${DNS_NAME}" $SSH_CMD
    fi
fi
