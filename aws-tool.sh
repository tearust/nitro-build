#!/bin/sh

if [ $1 = "id" ]; then
	aws ec2 describe-instances | jq '.Reservations[0].Instances[0].InstanceId'
elif [ $1 = "dns" ]; then
	aws ec2 describe-network-interfaces | jq -r '.NetworkInterfaces[0].Association.PublicDnsName'
elif [ $1 = "create" ]; then
	if [ -z "$3" ]; then
		aws ec2 run-instances --image-id ami-07464b2b9929898f8 --count 1 --instance-type c5.xlarge --key-name aws-tea-northeast2 --enclave-options 'Enabled=true'
	else
		aws ec2 run-instances --image-id $2 --count 1 --instance-type c5.xlarge --key-name $3 --enclave-options 'Enabled=true'
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
fi
