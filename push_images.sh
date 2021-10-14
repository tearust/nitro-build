#!/bin/bash

docker tag tearust/runtime:nitro realraindust/runtime:latest
docker push realraindust/runtime:latest

docker tag tearust/vmh-server:nitro realraindust/vmh-server:latest
docker push realraindust/vmh-server:latest

docker tag tearust/parent-instance-client:latest realraindust/parent-instance-client:latest
docker push realraindust/parent-instance-client:latest