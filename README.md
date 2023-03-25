## Configure on AWS
### Create IAM Policy
First you should create new IAM Policy to allow use the KMS key that we defined to used only inside the enclave. Open the "IAM -> Policies" page, and then press "Create Policy" button into the create policy page, then select "JSON" tab and paste json configs like the following:
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
After created the policy you should see a new policy like:
<img width="1301" alt="图片" src="https://user-images.githubusercontent.com/3713930/227701234-367b10f5-7f96-4b4c-b8ed-bd2143b2b62c.png">

For more information please read this [AWS doc](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-modifying-external-accounts.html#cross-account-key-policy).

### Create Role
Open the "IAM -> Roles" page and push the "Create role" button to create a new IAM role, then select the choice box in the first step like:
<img width="1574" alt="图片" src="https://user-images.githubusercontent.com/3713930/227701503-3d264683-71b7-4f72-a317-02c50b29db72.png">

In the second step we sugguest you input "key" as filter word and select "AWSKeyManagementServicePowerUser" and the IAM policy we created before like:
<img width="1560" alt="图片" src="https://user-images.githubusercontent.com/3713930/227701664-21289a5b-d6d8-4188-bdf9-a5db7b91d230.png">

Finally, enter the new role name and remember it for future use.

### Prepare security group
Select "EC2 -> Security Groups" page and choose a security group you what to modify(or create a new one), and add inbound rules like:
<img width="1300" alt="图片" src="https://user-images.githubusercontent.com/3713930/227702350-e21d191f-cd1e-49ec-90b9-1b40172775ce.png">

These input port will be used after node started.

### Create an EC2 instance
First select the region you what your EC2 instance be deployed to.

<img width="376" alt="图片" src="https://user-images.githubusercontent.com/3713930/227702512-8949e24c-c23f-478d-ad66-73246fe9d09e.png">

in the above image we choosed the "Asia Pacific (Seoul)" region and the region code is "ap-northeast-2", please keep this region code in mind because this the code will be used as the last paramters in "install" and "start" scripts below.

To ensure a successful instance launch, it's important to pay attention to the following points in the 'Launch an Instance' steps：

1. Choose the "Amazon Linux" OS like the following:
<img width="911" alt="图片" src="https://user-images.githubusercontent.com/3713930/227702887-e9659ccd-50fa-4d01-81f3-450afbef0186.png">

2. Choose an instance type that supported nitro, we use the "c5a.xlarge" here
<img width="940" alt="图片" src="https://user-images.githubusercontent.com/3713930/227702951-66326927-bdef-4cc8-a400-d50f42a124a6.png">

3. Use the security group we updated(created) above
<img width="938" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703076-21f6153f-3d7d-40ab-b902-1f073b8f9ea1.png">

4. (optinal) Is't better to increase volumn size from 8G to 30G
<img width="936" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703175-778599fa-5b13-4c66-974e-64eceb7995f8.png">

5. In the "Advanced details" tab use the IAM role we created above
<img width="931" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703322-136398dc-28fb-48b2-b7c9-964ef45ba595.png">

6. In the "advanced details" tab set "Nitro Enclave" as enabled
<img width="745" alt="图片" src="https://user-images.githubusercontent.com/3713930/227703431-d6763256-b3a3-4d08-a86a-42856cf824b7.png">

After successfully launching the EC2 instance, you can access it and proceed with the next steps of the tutorial.

## Run with EC2 instance

### Prepare
First you should prepare dependencies about the tea nodes, this should take about 10 minus. 
Please note that preparing related work need only once before start the nodes.

Run the following command to start or update new version:
```
bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/tearust/nitro-build/main/install.sh)"
```

Or using the following command without prompting:
```
bash -c "$(curl -H "Cache-Control: no-cache" -fsSL https://raw.githubusercontent.com/tearust/nitro-build/main/install.sh)" "" "0x0000000000000000000000000000000000000000000000000000000000000000" "0xbd6D4f56b59e45ed25c52Eab7EFf2c626e083db9" "ap-northeast-2"
```
### Start
Enter into the working directory like the following (the "nitro-build" folder created automatically in prepare step):

```
cd ~/nitro-build
```

Then simply run the following script to start the node with parts both inside and outside the enclave:
```
./start.sh
```
Or using the following command to run with overriding enviroment settings (TEA_ID, MACHINE_ID, etc):
```
./start.sh "0x0000000000000000000000000000000000000000000000000000000000000000" "0xbd6D4f56b59e45ed25c52Eab7EFf2c626e083db9" "ap-northeast-2"
```
