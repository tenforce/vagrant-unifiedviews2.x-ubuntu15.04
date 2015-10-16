#!/bin/bash
apt-get -y install git
mkdir -p /var/local/yasgui
( pushd /var/local ;
  git clone https://github.com/tenforce/yasgui-snapshot-oct-2015.git yasgui ;
  popd )
