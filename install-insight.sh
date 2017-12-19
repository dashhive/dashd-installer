#!/bin/bash

dash_prefix=/opt/dashcore
mkdir -p $dash_prefix

sudo apt install -y wget curl git python
NODE_PREFIX=$dash_prefix/node/lib/node_modules
NODE_VERSION=8.9.3
curl -fsSL bit.ly/node-installer | bash -s -- --no-dev-deps

git clone --depth 1 https://github.com/dashevo/bitcore-node-dash $dash_prefix/bitcore -b skip-dash-download

pushd $dash_prefix/bitcore
  npm install
  npm install insight-api-dash --S
  #OPTIONAL : If in addition to the API you also might want to have access to the UI explorer, in my exemple I assume you will
  npm install insight-ui-dash --S

  chmod a+x ./bin/bitcore-node-dash
  $dash_prefix/node/bin/node $dash_prefix/bitcore/bin/bitcore-node-dash
popd
