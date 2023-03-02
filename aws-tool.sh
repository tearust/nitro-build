#!/bin/bash

TAR_FILE_MODE="all"
SCRIPT_TAR="script.tar"
CLIENT_TAR="client.tar"
SINGLE_TAR="single.tar"
KMS_ROLE_NAME="KMS-test"

function tar_files() {
    SCRIPT_FILES="$SCRIPT_TAR *.sh *.yaml *.json .env --ignore-missing-args"
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
    aws ec2 describe-instances --filters Name=instance-state-name,Values=running | jq '.Reservations[].Instances[] | "\(.InstanceId) \(.State.Name)"'
elif [ $1 = "dns" ]; then
    aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[] | "\(.Attachment.InstanceId) \(.Association.PublicDnsName) \(.Association.PublicIp)"'
elif [ $1 = "create" ]; then
    IMAGE_ID=$2
    KEY_NAME=$3
    SECURITY_GROUP_IDS=$4
    : ${IMAGE_ID:="ami-013218fccb68a90d4"}
    : ${KEY_NAME:="aws-tea-northeast2"}
    : ${SECURITY_GROUP_IDS:="sg-a96a74d2"}

    aws ec2 run-instances \
        --image-id $IMAGE_ID \
        --count 1 \
        --instance-type c5a.xlarge \
        --key-name $KEY_NAME \
        --security-group-ids $SECURITY_GROUP_IDS \
        --enclave-options 'Enabled=true' \
        --block-device-mapping "[ { \"DeviceName\": \"/dev/xvda\", \"Ebs\": { \"VolumeSize\": 30 } } ]" \
        --iam-instance-profile Name="$KMS_ROLE_NAME"
elif [ $1 = "terminate" ]; then
    if [ -z "$2" ]; then
        aws ec2 describe-instances --filters Name=instance-state-name,Values=running | jq '.Reservations[0].Instances[0].InstanceId' | xargs aws ec2 terminate-instances --instance-ids
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
    : ${TAR_FILE_MODE:="script"}

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
    SUB_CMD=$2
    DNS_NAME=$3
    PEM_PATH=$4

    SSH_CMD="sh ./aws-prepare.sh $SUB_CMD"
    ssh_with

    echo "done!"
elif [ $1 = "scp" ]; then
    REMOTE_FILE=$2
    TARGET_PATH=$3
    DNS_NAME=$4
    PEM_PATH=$5

    scp_back

    echo "done!"
elif [ $1 = "role" ]; then
    set +e

    POLICY_NAME=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32)
    # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/create-policy.html
    POLICY_ARN=$(aws iam create-policy --policy-name $POLICY_NAME --policy-document '{
    	"Version": "2012-10-17",
    	"Statement": [
    		{
    			"Sid": "AttachKmsPolicy",
    			"Effect": "Allow",
    			"Action": [
    				"kms:Decrypt",
    				"kms:GenerateDataKey",
    				"kms:GenerateRandom"
    			],
    			"Resource": "arn:aws:kms:*:580177110170:key/f66b0a1b-28c7-49a1-82c8-70094dd7e45b"
    		}
    	]
    }' | jq -r '.[].Arn')
    echo "policy ARN is: $POLICY_ARN"

    aws iam delete-role --role-name $KMS_ROLE_NAME
    # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/create-role.html
    aws iam create-role --role-name $KMS_ROLE_NAME --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ec2.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }'
    aws iam attach-role-policy --role-name $KMS_ROLE_NAME --policy-arn $POLICY_ARN
    aws iam attach-role-policy --role-name $KMS_ROLE_NAME --policy-arn 'arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser'
    echo "Role created successfully"

    set -e
else
    echo "unknown command. Supported subcommand: ids, dns, create, terminate, ssh, push, install"
fi

set +e
