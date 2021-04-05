#!/bin/sh
echo "Run parent-instance-client inside /code after docker container starts"
docker run --network host -v /home/ec2-user:/code -w /code --rm -it ubuntu:20.10 /bin/bash
