How to install a Dash Full Node
-------

Dash is a fork of bitcoin which is backed by a company with a proof-of-stake governance model.

A "Full Node" is an installation of `dashd` (`bitcoind`) that requires a full copy of the blockchain.

The reason that you would want to "run a full node" for the Dash network is primarily if you want to
create a transaction on the blockchain on your own, not relying on blockcypher or other pay-to-play
API proxies.

This tutorial teaches you how to install a Dash Full Node as a **self-contained app** in `/opt/dashpay`.
This tutorial will work for Debian, Ubuntu (i.e. on Digital Ocean), Mint, Raspbian (i.e. on Raspberry Pi),
Windows (with the Ubuntu, Fedora, or Suse shells), and macOS (OS X).

There are a few steps that are Debian/Ubuntu-specific, but it should not be difficult to find
the commands you need for your specific operating system.

Screencast
------

[![How to Install a Dash Masternode the Quick'n'Easy Way](https://img.youtube.com/vi/jmas2iufBmM/0.jpg)](https://www.youtube.com/watch?v=jmas2iufBmM)

For the lazy: Automatic Installation
-------

If you're not really interested in "doing it the hard way" to learn the process,
I've created a script that automates all of these steps:

> <https://github.com/dashhive/dashd-installer.sh>

Be warned however that on a Raspberry Pi the CPU or RAM may overheat during the compile process,
causing it to fail with "internal errors" or "segmentation faults".
If that happens you'll need to manually pick up where it left off.

Step 1: Install OS-specfic dependencies
-----------

This is Debian (Ubuntu, Mint, etc) specific, so you'll need to find similar
instructions for `rpm` if you're using a RedHat (Fedora) or `brew`
if you're using macOS (OS X).

This just installs a bunch of tools for compiling C code as well as standard
dependencies that are readily available in your OS's package repositories (repos).

This step is fairly quick and all you need to do is copy/paste into a Terminal.
If you have a slow internet connection, the downloads could take several minutes
(it's a few hundred megabytes).

```bash
# Download the latest package listings
sudo apt update -y

# Optionally upgrade all existing packages to the laste versions
# sudo apt -y upgrade

# Install basic developer tools
sudo apt install -y wget curl git vim screen

# Install basic operating system tools and C compiler tools
sudo apt install -y build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils dh-autoreconf

# Install advanced C compiler tools for dashd (bitcoind)
sudo apt install -y libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
```

Although billions of dollars have been invested into bitcoin,
very little money has been put towards cleaning up the code base
and so it's quite bloated, much larger and more complex that in needs to be,
hence it's still written in a hardware and operating system language (C)
instead of having the parts that don't need to run directly on hardware
rewritten in a software and application language (such as Java or Go or Node or Python)
and it requires a *tonne* of dependencies.

Recommendation: Run this whole process in `screen`
------

A screen is a virtual Terminal that keeps your shell alive.

If you're running over ssh and get disconnected, screen will keep running
and you can reattach without having to start over.

```bash
# Create or attach to a "screen" named "awesome"
screen -xRS awesome
```

You can "detach" from a screen by hitting `<ctrl>+a, d`.
(that's the `<ctrl>` key at the same time as `a`, then let go and press `d`)

You can reattach to screen by running the same command above.

You can create a second (or third, or nth) screen by hitting `<ctrl>+a, c` (c for create).

You can rotate through screens by hitting `<ctrl>+a, n` (n for next).


Step 2: Create a self-contained app environment
-----

Because a number of dependencies with non-standard versions or compile
options are necessary to compile and run `dashd`, we're going to set some
environment variables so that they all install into one place and don't
clutter or confuse the rest of the applications that are part of the standard
packages of the operating system.

Additionally, if you ever want to start over fresh with a "clean slate",
you only need to remove a single directory rather than reinstalling your operating system.

First we'll create a directory structure in `/opt/dashpay` for all the dashpay-related things:

```bash
# Create a directory where everything related to dashpay will go
sudo mkdir -p /opt/dashpay

# Create a directory for the source files
sudo mkdir -p /opt/dashpay/src

# Create a directory for the config files
sudo mkdir -p /opt/dashpay/etc

# Create a directory for the blockchain files
sudo mkdir -p /opt/dashpay/var

# Make the directories owned by the current user
sudo chown -R $(whoami):$(whoami) /opt/dashpay/var
```


Next we'll set some environment variables that tell the compiler to use
these folders instead of the standard system folders:

**Note**: These are *temporary* settings.
If you reboot your computer or start a new Terminal or Shell during
this process, you'll need to rerun these commands.
Additionally, you should not do other custom compiles in the same shell.

```bash
export CPPFLAGS="-I/opt/dashpay/include ${CPPFLAGS:-}"
export CXXFLAGS="$CPPFLAGS"
export LDFLAGS="-L/opt/dashpay/lib ${LDFLAGS:-}"
export LD_RUN_PATH="/opt/dashpay/lib:${LD_RUN_PATH:-}"
export PKG_CONFIG_PATH="/opt/dashpay/lib/pkgconfig"
```

Step 3: Compile and install
-----------------

It's very likely that you don't have enough RAM to compile `dashd`,
so first we'll create temparary swap space (when you reboot, it'll be gone):

```bash
sudo fallocate -l 2G /tmp/tmp.swap
sudo mkswap /tmp/tmp.swap
sudo chmod 0600 /tmp/tmp.swap
sudo swapon /tmp/tmp.swap
```

We'll go into our `/opt/dashpay/src` folder

```bash
pushd /opt/dashpay/src
```

**Note**: Each of these next steps can take between several minutes (on a fast CPU) and *hours* (on a Raspberry Pi).

Next we need to install a special version of BerkleyDB:

```bash
# Download BDB v4.8
wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz

# Extract it
tar -xzvf db-4.8.30.NC.tar.gz

# Go into the folder
pushd db-4.8.30.NC/build_unix/

  # configure and compile it
  ../dist/configure --prefix=/opt/dashpay --enable-cxx
  make

  # install it to /opt/dashpay
  sudo make install
  sudo ldconfig

# back out of the folder
popd
```

Next we need special versions of libsodium (crypto) and ZeroMQ (rpc messaging):

```bash
# Download libsodium
wget https://github.com/jedisct1/libsodium/releases/download/1.0.3/libsodium-1.0.3.tar.gz

# Extract it
tar -zxvf libsodium-1.0.3.tar.gz

# Go into the folder
pushd libsodium-1.0.3/

  # configure and compile it
  ./configure --prefix=/opt/dashpay
  make

  # install it to /opt/dashpay
  sudo make install

# back out of the folder
popd
```

```bash
# This installs support for libzmq3, as strange as that may seem by the numbers
wget http://download.zeromq.org/zeromq-4.1.3.tar.gz
# alternate location (if the above is down for maintainance):
# https://github.com/zeromq/zeromq4-1/releases/download/v4.1.3/zeromq-4.1.3.tar.gz
tar -zxvf zeromq-4.1.3.tar.gz
pushd zeromq-4.1.3/

  ./configure --prefix=/opt/dashpay
  make

  sudo make install
  sudo ldconfig

popd
```

Now we install `dashd` itself, which will take a *very* long time -
probably 5 times as long as the other 3 combined.

```bash
# Download dashd
git clone --depth 1 https://github.com/dashpay/dash

# Go into the folder
pushd dash

  # Configure and compile
  ./autogen.sh
  ./configure --prefix=/opt/dashpay --without-gui
  make

  # install to /opt/dashpay
  sudo make install

# back out of the folder
popd
```

Since we're done compiling, we can manually remove the swap space if we want:

```bash
sudo swapoff /tmp/tmp.swap
sudo rm /tmp/tmp.swap
```

Lastly we can back out of `/opt/dashpay/src`:

```bash
popd
```

Step 4: Configure and Daemonize
---------------

The first thing we need to do is create an rpc user for `dashd`, which I'll arbitrarily call `dashrpc`.

Now we'll create a config file in `/opt/dashpay/etc/dash.conf` using that `rpcuser` and `rpcpassword`:

```bash
vi /opt/dashpay/etc/dash.conf
```

**To begin pasting in vi**: hit the letter `i` (insert mode)

`/opt/dashpay/etc/dash.conf`:

```
server=1
whitelist=0.0.0.0/0
txindex=1
addressindex=1
timestampindex=1
spentindex=1
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubrawtxlock=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
rpcuser=dashrpc
rpcpassword=CHANGE_ME_PLEASE
rpcport=9998
rpcallowip=0.0.0.0/0
uacomment=bitcore
#debug=1
#testnet=1
```

**To write (save) and quit (exit) vi**: hit `<esc>, :, w, q` to save and exit vi)

To run `dashd` you can do this:

```bash
/opt/dashpay/bin/dashd -conf=/opt/dashpay/etc/dash.conf -datadir=/opt/dashpay/var
```

**Note**: hit `<ctrl>+c` to quit dashd

Next we can have dashd run on system start with `systemd` by placing a config file in `/etc/systemd/system/dashd.service` and enabling it:


```bash
vi /etc/systemd/system/dashd.service
```

`/etc/systemd/system/dashd.service`:
```
[Unit]
Description=A Full Dash Node
Documentation=https://github.com/dashpay/dash
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
# Restart on crash (bad signal), but not on 'clean' failure (error exit code)
# Allow up to 3 restarts within 10 seconds
# (it's unlikely that a user or properly-running script will do this)
Restart=on-abnormal
StartLimitInterval=10
StartLimitBurst=3

# User and group the process will run as
# (git is the de facto standard on most systems)
User=dashpay
Group=dashpay

WorkingDirectory=/opt/dashpay
# custom directory cannot be set and will be the place where dashpay exists, not the working directory
Environment="LD_LIBRARY_PATH=/opt/dashpay/lib"
Environment="PKG_CONFIG_PATH=/opt/dashpay/lib/pkgconfig"
#ExecStart=/opt/dashpay/bin/dashd -daemon -conf=/opt/dashpay/etc/dash.conf -datadir=/opt/dashpay/var
ExecStart=/opt/dashpay/bin/dashd -conf=/opt/dashpay/etc/dash.conf -datadir=/opt/dashpay/var
ExecReload=/bin/kill -USR1 $MAINPID

# Limit the number of file descriptors and processes; see `man systemd.exec` for more limit settings.
# Unmodified dashpay is not expected to use more than this.
LimitNOFILE=1048576
LimitNPROC=64

# Use private /tmp and /var/tmp, which are discarded after dashpay stops.
PrivateTmp=true
# Use a minimal /dev
PrivateDevices=true
# Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
# Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
# ... except /opt/dashpay because we want a place for the database
# and /opt/dashpay/bin/dashd because we want a place where logs can go.
# This merely retains r/w access rights, it does not add any new.
# Must still be writable on the host!
ReadWriteDirectories=/opt/dashpay

# Note: in v231 and above ReadWritePaths has been renamed to ReadWriteDirectories
; ReadWritePaths=/opt/dashpay

# The following additional security directives only work with systemd v229 or later.
# They further retrict privileges that can be gained by dashpay.
# Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

Finally we put dashd under control of the user `dashpay` and start the service:

```bash
sudo adduser dashpay --home /opt/dashpay --disabled-password --gecos ''
sudo chown -R dashpay:dashpay /opt/dashpay/
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable dashd
sudo systemctl start dashd
```

Check the status of dashd with

```bash
sudo journalctl -xefu dashd
```

Congratulations
----------

You now have a Dash Full Node running.

The next thing that you'll want to do is to install the Insight API and UI so that you can see
incoming transactions and make your own using a web browser and web applications.
