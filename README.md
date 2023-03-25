## Run with EC2 instance

### Prepare
First we should prepare dependencies about our nodes, this should take about 10 minus. 
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