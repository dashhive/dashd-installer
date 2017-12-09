sudo apt-get update && sudo apt-get upgrade
sudo apt-get install git -y
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils -y
sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get install -y dh-autoreconf

#Option 1: Debian :
#echo "deb http://archive.debian.org/debian/ squeeze main contrib non-free" >> /etc/apt/sources.list

#Option 2: Ubuntu :
#sudo add-apt-repository ppa:bitcoin/bitcoin


sudo apt-get update -y


# If you don't have enough RAM (i.e. on Digital Ocean) you'll get an error like this:
# "g++: internal compiler error: Killed (program cc1plus)"
# so it's best to just go ahead and allocate some swap before the compile
# truncate -s 2048M /tmp.swap
fallocate -l 2G /tmp.swap
mkswap /tmp.swap
chmod 0600 /tmp.swap
swapon /tmp.swap

#########################
# Install BDB
#########################

# See also https://github.com/bitcoin/bitcoin/issues/2998
# https://github.com/bitcoin/bitcoin/blob/master/doc/build-unix.md#berkeley-db

#sudo apt-get install libdb4.8-dev libdb4.8++-dev -y --allow-unauthenticated

# not using https on purpose because oracle doesn't support it... :'(
wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
tar -xzvf db-4.8.30.NC.tar.gz
pushd db-4.8.30.NC/build_unix/
  ../dist/configure --prefix=/usr/local --enable-cxx
  make -j4
  sudo make install

  sudo bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/db-4.8.30.conf'
  sudo ldconfig

  #sudo ln -s /usr/local/BerkeleyDB.4.8 /usr/include/db4.8
  #sudo ln -s /usr/local/db4.8/include/* /usr/include
  #sudo ln -s /usr/local/db4.8/lib/* /usr/lib
popd

##########################
# Install ZeroMQ (libzmq3-dev)
##########################

#sudo apt-get install libzmq3-dev -y

wget https://github.com/jedisct1/libsodium/releases/download/1.0.3/libsodium-1.0.3.tar.gz
tar -zxvf libsodium-1.0.3.tar.gz
pushd libsodium-1.0.3/
  ./configure
  make
  sudo make install
popd

#wget https://archive.org/download/zeromq_3.2.5/zeromq-3.2.5.tar.gz
#tar -zxvf zeromq-3.2.5.tar.gz
#pushd zeromq-3.2.5/
#  ./configure
#  make
#  sudo make install
#  sudo ldconfig
#popd

wget http://download.zeromq.org/zeromq-4.1.3.tar.gz
tar -zxvf zeromq-4.1.3.tar.gz
pushd zeromq-4.1.3/
  ./configure
  make
  sudo make install
  sudo ldconfig
popd


#########################
# Install dashcore
#########################

mkdir dashcore
cd dashcore
git clone https://github.com/dashpay/dash

#Or if you want to test the last updates :
#git clone https://github.com/dashpay/dash -b v0.12.2.x


pushd dash
  ./autogen.sh
  ./configure
  make
popd

mkdir ~/.dashcore

swapoff /tmp.swap
rm /tmp.swap

apt -y install libzmq5 libzmq3-dev -y
