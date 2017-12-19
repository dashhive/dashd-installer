dashd-installer.sh
=======

[dashd-installer.sh](https://github.com/dashhive/dashd-installer.sh) |
[dash-insight-installer.sh](https://github.com/dashhive/dash-insight-installer.sh)

This script installs a dash full node on Debian based systems such as Ubuntu (i.e. on Digital Ocean) and Raspbian (i.e. on Raspberry Pi)

This installs the following components to `/opt/dashpay`:

* BerkleyDB
* libsodium
* ZeroMQ
* Dash Full Node [`dashpay/dash`](https://github.com/dashpay/dash)

Installation
-----

```bash
git clone https://github.com/dashhive/dash-insight-installer.sh.git
pushd ./dash-insight-installer
bash install.sh
```

Everything for `dashd` installs to `/opt/dashpay`:

```
/opt/dashpay/bin/dashd
/opt/dashpay/docs
/opt/dashpay/etc
/opt/dashpay/include
/opt/dashpay/lib
/opt/dashpay/share
```

Configuration
--------

The configs can be edited at:

```
/opt/dashpay/etc/dash.conf
```

daemon control
--------

`dashd` can be restarted with `systemctl`:

```bash
systemctl restart dashd
```

You can see the logs with `journalctl`:

```bash
journalctl -xefu dashd
```

You can disable and enable `dashd` loading on startup:

```bash
systemctl enable dashd
systemctl disable dashd
```

Manual daemon control
-----------------

```
install.sh
## TODO systemd file for dash
/opt/dashpay/bin/dashd -daemon -conf=/opt/dashpay/etc/dash.conf -datadir=/opt/dashpay/var
```

From testnet to mainnet
--------

Replace `testnet=1` with `testnet=0` in `~/.dashcore/dash.conf`

Setting rpcauth
--------

```
/opt/dashpay/dash/share/rpcuser/rpcuser.py dashd
String to be appended to /opt/dashpay/dash.conf:
rpcauth=dashd:d390a090f89a2354a8f2492cefd53$733490c2dddc50f61802d2038e9d238a75d3d1dec6ca19240cb9399d9a7728f1
Your password:
UHpQuY6Xde8_HJVWwEMn928n7-O4O3mrSwOZ0pR0-PM=
```

Resources
====

Based on https://medium.com/@obusco/setup-instant-send-transaction-the-comprehensive-way-a80a8a0572e
and http://raspnode.com/diyBitcoin.html

Troubleshooting
=====

configure: error: libdb_cxx headers missin
------------------------

Problem:

```
./configure

...

checking for Berkeley DB C++ headers... no
configure: error: libdb_cxx headers missing, Dash Core requires this library for wallet functionality (--disable-wallet to disable wallet functionality)
```

Solution:

```bash
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y --allow-unauthenticated
```

Or, if that fails:

```bash
wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
tar -xzvf db-4.8.30.NC.tar.gz
pushd db-4.8.30.NC/build_unix/
  ../dist/configure --prefix=/usr/local --enable-cxx
  make -j4
  sudo make install

  sudo bash -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/db-4.8.30.conf'
  sudo ldconfig
popd
```

configure: error: No working boost sleep implementation found.
------

Problem:

```
./configure

...

checking for mismatched boost c++11 scoped enums... ok
configure: error: No working boost sleep implementation found.
```

Solution:

```
sudo apt install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
```

Error: Failed to load masternode cache
--------

Problem:

```
Error: Failed to load masternode cache from /opt/dashpay/var/mncache.dat
```

Solution:

You've probably run out of disk space.

```bash
# assuming -datadir=/opt/dashpay/var/
rm /opt/dashpay/var/debug.log
```

You'll need to delete the caches:

```bash
# rm /opt/dashpay/var/{banlist.dat,fee_estimates.dat,governance.dat,mncache.dat,mnpayments.dat,netfulfilled.dat,peers.dat}

pushd /opt/dashpay/var/
  rm banlist.dat
  rm fee_estimates.dat
  rm governance.dat
  rm mncache.dat
  rm mnpayments.dat
  rm netfulfilled.dat
  rm peers.dat
popd
```

Killed
------

Problem:

Starts and then dies with no explanation.

It may think it's still running... ?

Solution:

In at least one case all I had to do was delete the lock and pid files:

```
rm .lock dashd.pid
```

ZMQ connection delay
------

Problem:

```
[2017-12-12T11:39:04.523Z] warn: ZMQ connection delay: tcp://127.0.0.1:28332
```

```
netcat -v localhost 28332
# Connection refused
```

[Test](https://bitcoin.stackexchange.com/a/65066/68465):

You can know for sure that the

```
grep -r 'ENABLE_ZMQ' /opt/dashpay/deps/dash/config.log
```

If you see `#define ENABLE_ZMQ 0` instead of `#define ENABLE_ZMQ 1`, then you definitely don't have ZMQ support compiled in.

Solution:

You should use `--prefix=/usr/local` when compiling libsodium, libzmq3, and then again
when compiling `bitcore`/`dashd` itself.

```
./configure --prefix=/usr/local
```
