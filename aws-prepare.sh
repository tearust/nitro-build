#!/bin/sh

set -eu

# install nitro cli related packages
sudo amazon-linux-extras install aws-nitro-enclaves-cli -y
sudo yum install aws-nitro-enclaves-cli-devel -y
sudo yum -y install git
sudo yum install openssl11 -y
sudo usermod -aG ne ec2-user
sudo usermod -aG docker ec2-user
sudo curl https://raw.githubusercontent.com/tearust/nitro-build/main/allocator.yaml -o /etc/nitro_enclaves/allocator.yaml
sudo systemctl start nitro-enclaves-allocator.service && sudo systemctl enable nitro-enclaves-allocator.service
sudo systemctl start docker && sudo systemctl enable docker
sudo yum install bison -y
sudo yum install -y gcc libgcc kernel-devel make ncurses-devel

# sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
# sudo chmod +x /usr/local/bin/docker-compose
. ./docker_install.sh
echo "install basic dependencies completed"

# install make 4.3
wget https://ftp.gnu.org/gnu/make/make-4.3.tar.gz
tar -xzvf make-4.3.tar.gz
cd make-4.3/
./configure --prefix=/usr/local/make
make -j$(nproc) && sudo make install
cd /usr/bin/
sudo mv make make.bak # backup
sudo ln -sv /usr/local/make/bin/make /usr/bin/make
cd ~
rm make-4.3.tar.gz
rm -rf make-4.3
echo "install make 4.3 completed"

# install glibc 2.29
wget https://ftp.gnu.org/gnu/glibc/glibc-2.29.tar.gz
tar -xzvf glibc-2.29.tar.gz && cd glibc-2.29/
mkdir build && cd build
../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
make -j$(nproc) && sudo make install
cd ~
rm glibc-2.29.tar.gz
rm -rf glibc-2.29
echo "install glibc 2.29 completed"

if [ -n $1 ] && [ $1 = "tool" ]; then
  # DOWNLOAD SOURCES FOR LIBEVENT AND MAKE AND INSTALL
  curl -LOk https://github.com/libevent/libevent/releases/download/release-2.1.11-stable/libevent-2.1.11-stable.tar.gz
  tar -xf libevent-2.1.11-stable.tar.gz
  cd libevent-2.1.11-stable
  ./configure --prefix=/usr/local
  make -j$(nproc)
  sudo make install
  # DOWNLOAD SOURCES FOR TMUX AND MAKE AND INSTALL
  curl -LOk https://github.com/tmux/tmux/releases/download/3.0a/tmux-3.0a.tar.gz
  tar -xf tmux-3.0a.tar.gz
  cd tmux-3.0a
  LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local
  make -j$(nproc)
  sudo make install
  cd ~
  rm libevent-2.1.11-stable.tar.gz tmux-3.0a.tar.gz
  rm -rf libevent-2.1.11-stable
  rm -rf tmux-3.0a
  echo "install tmux completed"

  mkdir -p ~/.config/fish
  cd /etc/yum.repos.d/
  sudo wget --no-check-certificate https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_7/shells:fish:release:3.repo
  sudo yum -y install fish
  echo "install fish completed"

  sudo sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
  if [ ! -d "~/.tmux/plugins/tpm" ]; then
  	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi
  if [ ! -d "~/dotfiles" ]; then
  	git clone -b ubuntu_lint https://github.com/raindust/dotfiles ~/dotfiles
  fi
  cd ~/dotfiles
  ./apply.sh
  tmux source ~/.tmux.conf
  ~/.tmux/plugins/tpm/bin/install_plugins

  if [ -n $2 ] && [ $2 = "dev" ]; then
    # install general development related packages
    curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
    rustup target add x86_64-unknown-linux-musl
    rustup target add wasm32-unknown-unknown

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
  fi
else
  sudo yum install tmux -y || true
fi

echo "install dependencies completed"
sudo localedef -i en_US -f UTF-8 en_US.UTF-8