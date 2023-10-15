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
            "Resource": "arn:aws:kms:*:580177110170:key/f66b0a1b-28c7-49a1-82c8-70094dd7e45b"
        }
    ]
}
```
After creatiing the policy you should see a new policy like this:

<img width="1301" alt="图片" src="https://user-images.githubusercontent.com/3713930/227701234-367b10f5-7f96-4b4c-b8ed-bd2143b2b62c.png">

For more information please read this [AWS docs](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-modifying-external-accounts.html#cross-account-key-policy).

### Create Role
Open the "IAM -> Roles" page and click the "Create role" button to create a new IAM role, then select the choice box in the first step like:
<img width="1574" alt="图片" src="https://user-images.githubusercontent.com/3713930/227701503-3d264683-71b7-4f72-a317-02c50b29db72.png">

In the second step we suggest you input "key" as filter word and select "AWSKeyManagementServicePowerUser" and the IAM policy we created before like:
<img width="1560" alt="图片" src="https://user-images.githubusercontent.com/3713930/227701664-21289a5b-d6d8-4188-bdf9-a5db7b91d230.png">

Finally, enter the new role name and remember it for future use.

### Prepare the security group
Select "EC2 -> Security Groups" page and choose a security group you want to modify (or create a new one) and add inbound rules as follows:
<img width="1285" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/2a7094c3-9c07-4565-8db8-58a299f41403">


These input ports will be filtered after the node is started.

### Create an EC2 instance
First select the region you want your EC2 instance to be deployed to.

<img width="376" alt="图片" src="https://user-images.githubusercontent.com/3713930/227702512-8949e24c-c23f-478d-ad66-73246fe9d09e.png">

In the above image we choose the "Asia Pacific (Seoul)" region and the region code is "ap-northeast-2". Please keep this region code in mind because this the code will be used as the last parameter in "install" and "start" scripts below.

To ensure a successful instance launch, pay closse attention to the following parts in the 'Launch an Instance' steps：

1. Choose the "Amazon Linux" OS like the following (DO NOT use the default "Amazon Linux 2023 AMI" option, and architecture choose "64-bit(Arm)"):
<img width="933" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/53cebe9b-38fc-4ec4-8c91-8abbf3f9ede5">

2. Choose an instance type that supports nitro. We use the "c6g.xlarge" here
<img width="935" alt="图片" src="https://github.com/tearust/nitro-build/assets/3713930/44fc708d-0753-4520-9b91-7b80cfd555d1">

3. Use the security group we updated (created) above:
<img width="938" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703076-21f6153f-3d7d-40ab-b902-1f073b8f9ea1.png">

4. (optinal) It's better to increase the volume size from 8G to 30G:
<img width="936" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703175-778599fa-5b13-4c66-974e-64eceb7995f8.png">

5. In the "Advanced details" tab, use the IAM role we created above:
<img width="931" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703322-136398dc-28fb-48b2-b7c9-964ef45ba595.png">

6. In the "advanced details" tab set "Nitro Enclave" as enabled
<img width="745" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703431-d6763256-b3a3-4d08-a86a-42856cf824b7.png">

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
bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/tearust/nitro-build/main/install.sh)" "" "0x0000000000000000000000000000000000000000000000000000000000000000" "0xbd6D4f56b59e45ed25c52Eab7EFf2c626e083db9" "ap-northeast-2"
```

The above command uses the region code of `ap-northeast-2` but you should change this according to the region you use (i.e. an Oregon server will have a `us-west-2` region code).

### Start
Enter into the working directory of the "nitro-build" folder created automatically in the preparation step:

```
cd ~/nitro-build
```

Then simply run the following script to start the node with parts both inside and outside the enclave:
```
./start.sh "{YOUR_MACHINE_ID}" "{YOUR_MACHINE_OWNER}" "{REGION_CODE}"
```
Note that replace your real machine_id, machine_owner and region_code for the above command. 
e.g. ``` ./start.sh "0x0000000000000000000000000000000000000000000000000000000000000000" "0xbd6D4f56b59e45ed25c52Eab7EFf2c626e083db9" "ap-northeast-2" ```

