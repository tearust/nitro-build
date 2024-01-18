## Configure on AWS
### Create IAM Policy
First you should create new IAM Policy to allow use of the KMS key that we defined to only be used inside the enclave. Open the "IAM -> Policies" page, and then click the "Create Policy" button to load the create policy page. You'll next select the "JSON" tab and paste the following json configs:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:GenerateDataKey",
                "kms:GenerateRandom"
            ],
            "Resource": "arn:aws:kms:ap-northeast-2:580177110170:key/d457ce32-1226-420b-9e81-bc32c49fe2da"
        }
    ]
}
```
After creatiing the policy you should see a new policy like this:

<img width="1198" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/f4f47428-1014-499b-8d79-d1ead4307c3e">

For more information please read this [AWS docs](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-modifying-external-accounts.html#cross-account-key-policy).

### Create Role
Open the "IAM -> Roles" page and click the "Create role" button to create a new IAM role, then select the choice box in the first step like:
<img width="1531" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/efb900bd-9e35-47eb-b1e6-13d820e420fa">

In the second step we suggest you input "key" as filter word and select "AWSKeyManagementServicePowerUser" and the IAM policy we created before like:
<img width="1270" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/b7a65973-b67b-4796-9590-e15d80d0b5a8">

Finally, enter the new role name and remember it for future use.

### Prepare the security group
Select "EC2 -> Security Groups" page and choose a security group you want to modify (or create a new one) and add inbound rules as follows:
<img width="1285" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/2a7094c3-9c07-4565-8db8-58a299f41403">


These input ports will be filtered after the node is started.

### Create an EC2 instance

To ensure a successful instance launch, pay closse attention to the following parts in the 'Launch an Instance' steps：

1. Choose the "Amazon Linux" OS like the following (DO NOT use the default "Amazon Linux 2023 AMI" option, and architecture choose "64-bit(Arm)"):
<img width="933" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/53cebe9b-38fc-4ec4-8c91-8abbf3f9ede5">

2. Choose an instance type that supports nitro. We use the "c6g.xlarge" here
<img width="935" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/44fc708d-0753-4520-9b91-7b80cfd555d1">

3. Use the security group we updated (created) above:
<img width="938" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703076-21f6153f-3d7d-40ab-b902-1f073b8f9ea1.png">

4. Increase the volume size from 8G to 200G:
<img width="935" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/9ccd12ce-a9b7-4d51-8e1b-c9cc1e4811f1">

5. In the "Advanced details" tab, use the IAM role we created above:
<img width="940" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/031c6a8a-e6b7-4364-9fa3-e70d1c91f198">

6. In the "advanced details" tab set "Nitro Enclave" as enabled
<img width="865" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/ab72cc7e-5e8c-4920-b117-55af17e2543e">

After successfully launching the EC2 instance, you can access it and proceed with the next steps of the tutorial.

## Run with EC2 instance

### Prepare
First you should prepare the TEA node dependencies which should take about 10 minutes.

Please note that the following preparations need only be completed once before starting the node for the first time.

Run the following command to start or update new TEA software version:
```
bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/tearust/nitro-build/main/install.sh)"
```

Or using the following command without prompting:
```
bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/tearust/nitro-build/main/install.sh)" "" "0x0000000000000000000000000000000000000000000000000000000000000000" "0xbd6D4f56b59e45ed25c52Eab7EFf2c626e083db9" "<your startup proof>"
```

### Start
Enter into the working directory of the "nitro-build" folder created automatically in the preparation step:

```
cd ~/nitro-build
```

Then simply run the following script to start the node with parts both inside and outside the enclave:
```
./start.sh
```
or run the following command if you want to change settings when running:
```
./start.sh "{YOUR_MACHINE_ID}" "{YOUR_MACHINE_OWNER}" "{STARTUP_PROOF}"
```
Note that replace your real machine_id, machine_owner and startup_proof for the above command. 
e.g. ``` ./start.sh "0x0000000000000000000000000000000000000000000000000000000000000000" "0xbd6D4f56b59e45ed25c52Eab7EFf2c626e083db9" "0x1234321" ```

