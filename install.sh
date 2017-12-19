#!/bin/bash
set -u
set -e

my_tmpd=/opt/dashpay/deps
mkdir -p $my_tmpd
#my_tmpd=$(mktemp -d)
echo "#################################"
echo "##  tmpdir: $my_tmpd  ##"
echo "#################################"
dash_prefix=/opt/dashpay
#my_prefix=/usr/local
my_prefix=/opt/dashpay
sudo mkdir -p $dash_prefix/etc $dash_prefix/var
sudo mkdir -p $my_prefix

export CPPFLAGS="-I$my_prefix/include ${CPPFLAGS:-}"
export CXXFLAGS="$CPPFLAGS"
export LDFLAGS="-L$my_prefix/lib ${LDFLAGS:-}"
#export LD_RUN_PATH="$my_prefix/lib:${LD_RUN_PATH:-}"
export PKG_CONFIG_PATH="$my_prefix/lib/pkgconfig"

#source ./installer/ubuntu.sh
sudo apt update -y # && sudo apt -y upgrade
sudo apt install -y wget curl git
sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils dh-autoreconf
sudo apt install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev

#Option 1: Debian :
#echo "deb http://archive.debian.org/debian/ squeeze main contrib non-free" >> /etc/apt/sources.list
#sudo apt-get update -y

#Option 2: Ubuntu :
#sudo add-apt-repository ppa:bitcoin/bitcoin
#sudo apt-get update -y



#Option 3: Install from source rather than tainting OS repos

pushd $my_tmpd

  #########################
  # swap on
  #########################

  # If you don't have enough RAM (i.e. on Digital Ocean) you'll get an error like this:
  # "g++: internal compiler error: Killed (program cc1plus)"
  # so it's best to just go ahead and allocate some swap before the compile
  # truncate -s 2048M /tmp.swap
  fallocate -l 2G ./tmp.swap
  mkswap ./tmp.swap
  chmod 0600 ./tmp.swap
  swapon ./tmp.swap



  #########################
  # Install BDB
  #########################
  #sudo apt-get install libdb4.8-dev libdb4.8++-dev -y --allow-unauthenticated

  # See also https://github.com/bitcoin/bitcoin/issues/2998
  # https://github.com/bitcoin/bitcoin/blob/master/doc/build-unix.md#berkeley-db

  # not using https on purpose because oracle doesn't support it... :'(
  wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
  tar -xzvf db-4.8.30.NC.tar.gz
  pushd db-4.8.30.NC/build_unix/
    ../dist/configure --prefix=$my_prefix --enable-cxx # --disable-shared
    make # -j2
    sudo make install

    sudo ldconfig
  popd



  ##########################
  # Install ZeroMQ (libzmq3-dev)
  ##########################
  #sudo apt -y install libzmq5 libzmq3-dev -y

  wget https://github.com/jedisct1/libsodium/releases/download/1.0.3/libsodium-1.0.3.tar.gz
  tar -zxvf libsodium-1.0.3.tar.gz
  pushd libsodium-1.0.3/
    ./configure --prefix=$my_prefix
    make # -j2
    sudo make install
  popd

  # This installs support for libzmq3, as strange as that may seem by the numbers
  wget http://download.zeromq.org/zeromq-4.1.3.tar.gz
  tar -zxvf zeromq-4.1.3.tar.gz
  pushd zeromq-4.1.3/
    ./configure --prefix=$my_prefix
    make # -j2
    sudo make install
    sudo ldconfig
  popd



  #########################
  # Install dash
  #########################

  git clone --depth 1 https://github.com/dashpay/dash
  #Or if you want to test the last updates :
  #git clone https://github.com/dashpay/dash -b v0.12.2.x

  pushd dash
    ./autogen.sh
    ./configure --prefix=$my_prefix --without-gui # --disable-wallet | tee config.log.txt # --without-miniupnpc --with-incompatible-bdb
    make # -j2
    sudo make install
  popd

  #########################
  # swap off
  #########################

  swapoff ./tmp.swap
  rm ./tmp.swap

popd

sudo adduser dashpay --home /opt/dashpay --disabled-password --gecos ''
sudo rsync -av ./dash.conf $dash_prefix/etc/
sudo chown -R dashpay:dashpay $dash_prefix/
sudo rsync -av ./dist/etc/systemd/system/dashd.conf /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable dashd
sudo systemctl start dashd
