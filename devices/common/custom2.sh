#!/bin/bash

shopt -s extglob

#sed -i '$a src-git miaogongzi https://github.com/mgz0227/OP-Packages.git;master' feeds.conf.default
sed -i "/telephony/d" feeds.conf.default
sed -i -E "s#git\.openwrt\.org/(openwrt|feed|project)#github.com/openwrt#" feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

cp -f devices/common/.config .config

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl


cp -f devices/common/po2lmo staging_dir/host/bin/po2lmo
chmod +x staging_dir/host/bin/po2lmo