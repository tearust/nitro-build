FROM ubuntu:20.10

ADD ipfs /root/ipfs

ENV IPFS_PATH=/root/ipfs

WORKDIR /root/ipfs
CMD ["./ipfs", "daemon"]