#!/bin/bash

dash_prefix=/opt/dashcore
my_npm="$dash_prefix/node/bin/node $dash_prefix/node/bin/npm"
mkdir -p $dash_prefix

sudo apt install -y wget curl git python
export NODE_PATH=$dash_prefix/node/lib/node_modules
export NODE_VERSION=v8.9.3
export PATH=$dash_prefix/node/bin:$PATH
echo $NODE_VERSION > /tmp/NODEJS_VER
curl -fsSL bit.ly/node-installer | bash -s -- --no-dev-deps

git clone --depth 1 https://github.com/dashevo/bitcore-node-dash $dash_prefix/bitcore -b skip-dash-download

pushd $dash_prefix/bitcore
  $my_npm install
  $my_npm install insight-api-dash --S
  #OPTIONAL : If in addition to the API you also might want to have access to the UI explorer, in my exemple I assume you will
  $my_npm install insight-ui-dash --S

  chmod a+x ./bin/bitcore-node-dash
  $dash_prefix/node/bin/node $dash_prefix/bitcore/bin/bitcore-node-dash start -c $dash_prefix/
popd
