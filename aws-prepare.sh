#!/bin/sh

# install nitro cli related packages
sudo amazon-linux-extras install aws-nitro-enclaves-cli -y
sudo yum install aws-nitro-enclaves-cli-devel -y
sudo yum -y install git
sudo yum -y install tmux
sudo usermod -aG ne ec2-user
sudo usermod -aG docker ec2-user
sudo curl https://raw.githubusercontent.com/tearust/nitro-build/main/allocator.yaml -o /etc/nitro_enclaves/allocator.yaml
sudo systemctl start nitro-enclaves-allocator.service && sudo systemctl enable nitro-enclaves-allocator.service
sudo systemctl start docker && sudo systemctl enable docker

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

if [ -n $1 ] && [ $1 = "dev" ]; then
  # install general development related packages
  curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup target add x86_64-unknown-linux-musl
  rustup target add wasm32-unknown-unknown
  sudo yum -y install gcc

  if [ -n $2 ] && [ $2 = "enclave" ]; then
    # install wascc related packages
    cargo install nkeys --features "cli"
    cargo install wascap --version ^0.5 --features "cli"

    # install musl
    mkdir ~/musl && cd ~/musl
    wget https://musl.libc.org/releases/musl-1.2.2.tar.gz
    tar xzvf musl-1.2.2.tar.gz
    cd -
    cd ~/musl/musl-1.2.2/
    ./configure
    make -j$(nproc)
    sudo make install
    cd -

    # install openssl
    sudo yum install -y openssl11-devel
  fi
fi