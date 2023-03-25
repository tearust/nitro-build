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
