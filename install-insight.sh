#!/bin/bash
set -u
set -e

my_prefix=/opt/dashpay
dash_prefix=/opt/dashpay
export NODE_PATH=$dash_prefix/lib/node_modules
export NODE_VERSION=v8.9.3
export PKG_CONFIG_PATH=$my_prefix/lib/pkgconfig
mkdir -p $dash_prefix

export CPPFLAGS="-I$my_prefix/include ${CPPFLAGS:-}"
export CXXFLAGS="$CPPFLAGS"
export LDFLAGS="-L$my_prefix/lib ${LDFLAGS:-}"
#export LD_RUN_PATH="$my_prefix/lib:$LD_RUN_PATH"
export PKG_CONFIG_PATH="$my_prefix/lib/pkgconfig"

sudo apt install -y wget curl git python
export PATH=$dash_prefix/bin:$PATH
echo $NODE_VERSION > /tmp/NODEJS_VER
curl -fsSL bit.ly/node-installer | bash -s -- --no-dev-deps

git clone --depth 1 https://github.com/dashevo/bitcore-node-dash $dash_prefix/bitcore -b skip-dash-download

pushd $dash_prefix/bitcore
  my_node="$dash_prefix/bin/node"
  my_npm="$my_node $dash_prefix/bin/npm"
  $my_npm install
  $my_npm install insight-api-dash --S
  #OPTIONAL : If in addition to the API you also might want to have access to the UI explorer, in my exemple I assume you will
  $my_npm install insight-ui-dash --S

  chmod a+x ./bin/bitcore-node-dash
  LD_LIBRARY_PATH="$my_prefix/lib:${LD_RUN_PATH:-}" $my_node $dash_prefix/bitcore/bin/bitcore-node-dash start -c $dash_prefix/
popd

rsync -av ./bitcore-node-dash.json /opt/dashpay/etc/
