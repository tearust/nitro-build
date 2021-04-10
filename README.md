# nitro-build


This repo is all about running TEA Node in AWS Nitro.

## Background and concepts

AWS Nitro runs on an AWS C5.xlarge or other larger instances.

Enclave is a isolated hardware-protected virtual machine inside its parent instance. 

Tea-runtime is running inside the enclave. It can communicate with outside world using vsock only.

Parent-instance-client is running inside a docker container outside of the enclave. 

VMH-server is the service that relay all message between parent-instance-client and tea-runtime. 

On one hand, vmh-server communicate with tea-runtime inside the enclave via vsock, on the other hand, vmh-server communicate with parent-instance-client that running inside the docker container via tcp.

## Use aws-tool.sh to create EC2 instance
### create new instance

Run the following command to create a new instance:
```
./aws-tool.sh create [image-id] [key-name] [security-group-id]
```
Here are the descriptions about parameters with `create` subcommand:
- [image-id]: (optional) image id that EC2 instance OS system installed from, default is "ami-07464b2b9929898f8" whith is only avaliable in the northeast2 region
- [key-name]: (optional) the key name create in KMS, default is "aws-tea-northeast2" that is the key name created in my KMS.
- [security-group-id]: (optional) the id about the security group you want your EC2 instance apply to, default is "sg-a96a74d2" that is my security group id

### push resources into EC2 instance
Run the following command to push resources into EC2 instance:
```
./aws-tool.sh push [pem key path] [push mode] [dns or ip address]
```
Here are the descriptions about parameters with `push` subcommand:
- [pem key path]: (optional) corresponding with [key-name] in the create new instance step, default value is "~/.ssh/aws-tea-northeast2.pem" that is my pem file path
- [push mode]: (optional) value can be `all`, `script`, `client`, and `vmh`, default is `all` that pull all resources into EC2 instance
- [dns or ip address]: (optional) the host address that ssh connect to, default is queried by `aws ec2 describe-network-interfaces` and parsed from the query result

### prepare EC environment
After pushed resources into EC2 instance, run the following command to prepare EC2 instance:
```
./aws-tool.sh install [pem key path] [dns or ip address]
```
Here are the descriptions about parameters with `install` subcommand:
- [pem key path]: (optional) corresponding with [key-name] in the create new instance step, default value is "~/.ssh/aws-tea-northeast2.pem" that is my pem file path
- [dns or ip address]: (optional) the host address that ssh connect to, default is queried by `aws ec2 describe-network-interfaces` and parsed from the query result

### ssh into EC2 instance
Run the following command to ssh into the created instance:
```
./aws-tool.sh ssh [pem key path] [dns or ip address]
```
Here are the descriptions about parameters with `ssh` subcommand:
- [pem key path]: (optional) corresponding with [key-name] in the create new instance step, default value is "~/.ssh/aws-tea-northeast2.pem" that is my pem file path
- [dns or ip address]: (optional) the host address that ssh connect to, default is queried by `aws ec2 describe-network-interfaces` and parsed from the query result

### terminate instance
Run the following command to terminate the instance:
```
./aws-tool.sh terminate [instance ids]
```
Here are the descriptions about parameters with `terminate` subcommand:
- [instance ids]: (optional) id of the EC2 instance to be terminated, default is the first instance id queried by `aws ec2 describe-instances` command

If you have multiple instance running, or some instances are in shutting down mode, this command may not terminate the current running instance successfully. Please make sure to run `./aws-tool.sh ids` after this command to make sure that the instance is actually in "shutting down mode".

### list all EC2 instances
Run the following command to list all EC2 instances ids and corresponding status:
```
./aws-tool.sh ids
```

### list all EC2 dns addresses
Run the following command to list all EC2 instances ids and corresponding dns addresses:
```
./aws-tool.sh dns
```

## After ssh into the EC2 instance, continue deploying enclae

### Use tmux for multiple shell running

After ssh into the EC2 instance, run tmux to help you handle the multiple shells in the following steps.

run `tmux` or `tmux a` if you already have a tmux session

### build enclave image

```
./enclave.sh docker 
```
to build enclave image from docker hub image: tearust/runtime:nitro

if you have you own docker repo, use

```
./enclave.sh docker YOUR_DOCKER_ACCOUNT
```
instead

### start enclave and tea-runtime

run 
```
./enclave.sh debug 
```
to run enclave image in debug mode, then you should the an enclave id, copy this enclave for the next step

### Check enclave status and id

Run `./enclave.sh list` anytime you want to make sure if there is an enclave running

After running the enclave app, you should following the next step to run client app on the parent instance side:

### start vmh-server

run

```
./vmh-server
```

### start aprent-instance-client

press Ctrl+B + C to create a new tmux tab page or Ctrl+B + N to switch to the client app tab page if you already have one

```
./client-docker.sh
```

Now, you should see the promopt again. This promopt is the docker container's prompt. That means you are inside the docker container now.

You can run provider_kvp or parent-instance-client for testing. You can also switch between two tmux session by press `ctrl+b n` to check logs. Make sure all three programs running ok.

## use ipfs.sh to build ipfs image
### compile ipfs executable

use the following command to compile ipfs executable:
```
./ipfs.sh compile
```
after compile there will be two executable in the ipfs subdirectory:
- ipfs: executable for running natively
- ipfs-linux: executable for package into docker image 

### build docker images
use the following command to build ipfs docker image:
```
./ipfs.sh build [dockerhub account]
```
Here are the descriptions about parameters with `build` subcommand:
- [dockerhub account]: (optional) docker-hub account that push the docker image into

### run docker container
use the following command to run the ipfs docker container:
```
./ipfs.sh run [dockerhub account]
```
Here are the descriptions about parameters with `build` subcommand:
- [dockerhub account]: (optional) docker-hub account that will pull the docker image
