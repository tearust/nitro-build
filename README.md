# nitro-build


This repo is all about running TEA Node in AWS Nitro.


AWS Nitro runs on an AWS C5.xlarge or other larger instances.

Enclave is a isolated hardware-protected virtual machine inside its parent instance. 

Tea-runtime is running inside the enclave. It can communicate with outside world using vsock only.

Parent-instance-client is running inside a docker container outside of the enclave. 

VMH-server is the service that relay all message between parent-instance-client and tea-runtime. 

On one hand, vmh-server communicate with tea-runtime inside the enclave via vsock, on the other hand, vmh-server communicate with parent-instance-client that running inside the docker container via tcp.



## Aws EC2 Environment prepare
create an Aws EC2 instance, choose the c5.xlarge host type and enable the Enclave option, please see [here](https://github.com/tearust/research/blob/main/aws/nitro/nitro%E7%8E%AF%E5%A2%83%E5%87%86%E5%A4%87.md) to get more details

Once the EC2 instance is created and running. ssh into the EC2 instance

You can run the following command to prepare EC2 environment:
```
curl -sSL https://raw.githubusercontent.com/tearust/nitro-build/main/aws-prepare.sh | sh
```

and if you want to additionally prepare vmh-server related compilation enviroment, please run the following command:
```
curl -sSL https://raw.githubusercontent.com/tearust/nitro-build/main/aws-prepare.sh | sh -s -- dev
```

and if you want to additionally prepare enclave-app related compilation enviroment, please run the following command:
```
curl -sSL https://raw.githubusercontent.com/tearust/nitro-build/main/aws-prepare.sh | sh -s -- dev enclave
```

press Ctrl+D to quit ssh connection to apply those configuration settings take effect.

### Use tmux for multiple shell running

ssh into the EC2 instance again. This time, all config should take effect.

tmux can help you handle the multiple shells in the following steps.

run `tmux` or `tmux a` if you already have a tmux session

### clone nitro-build repo

```
git clone https://github.com/tearust/nitro-build
```

Once done, enter the code repo by `cd nitro-build`

### initialize enclave environment

```

sudo ./enclave-init.sh

```
this is required at the first time you run the test, after that you shall skip this step.

### build enclave image

```
./enclave.sh docker 
```
to build enclave image from docker hub image: tearust/runtime:nitro
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
chmod +x ./parent-client.sh
./parent-client.sh
```

Now, you should see the promopt again. This promopt is the docker container's prompt. That means you are inside the docker container now.

You can run provider_kvp or parent-instance-client for testing. You can also switch between two tmux session by press `ctrl+b n` to check logs. Make sure all three programs running ok.

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