#!/bin/bash

sudo ip link set dev eth0 mtu 1500
echo "MTU=1500" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0
echo "request subnet-mask, broadcast-address, time-offset, routers, domain-name, domain-search, domain-name-servers, host-name, nis-domain, nis-servers, ntp-servers;" | sudo tee -a /etc/dhcp/dhclient.conf
sudo systemctl restart network.service

sudo yum erase 'ntp*'
sudo yum install chrony
echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" | sudo tee -a /etc/chrony.conf
sudo systemctl restart chronyd.service
sudo systemctl enable chronyd.service