sudo apt install -y python

mkdir insight
pushd insight
  git clone --depth 1 https://github.com/dashevo/bitcore-node-dash -b skip-dash-download
  pushd bitcore-node-dash
    npm install
    npm install insight-api-dash --S
    #OPTIONAL : If in addition to the API you also might want to have access to the UI explorer, in my exemple I assume you will
    npm install insight-ui-dash --S

    chmod a+x ./bin/bitcore-node-dash
  popd
popd
