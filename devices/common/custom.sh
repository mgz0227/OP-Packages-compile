#!/bin/bash

shopt -s extglob

sed -i '$a src-git miaogongzi https://github.com/mgz0227/OP-Packages.git;master' feeds.conf.default
sed -i "/telephony/d" feeds.conf.default
sed -i -E "s#git\.openwrt\.org/(openwrt|feed|project)#github.com/openwrt#" feeds.conf.default
sed -i '/	refresh_config();/d' scripts/feeds

./scripts/feeds update -a

rm -rf feeds/miaogongzi/{diy,mt-drivers,shortcut-fe,luci-app-mtwifi,base-files,luci-app-package-manager,\
dnsmasq,firewall*,wifi-scripts,opkg,ppp,curl,luci-app-firewall,\
nftables,fstools,wireless-regdb,libnftnl,netdata}
rm -rf feeds/packages/libs/libcups

curl -sfL https://raw.githubusercontent.com/openwrt/packages/master/lang/golang/golang/Makefile -o feeds/packages/lang/golang/golang/Makefile

mv -f feeds/miaogongzi/{rust-bindgen,go-rice,gn}  feeds/packages/devel/

for ipk in $(find feeds/miaogongzi/* -maxdepth 0 -type d);
do
	[[ "$(grep "KernelPackage" "$ipk/Makefile")" && ! "$(grep "BuildPackage" "$ipk/Makefile")" ]] && rm -rf $ipk || true
done

#<<'COMMENT'
rm -Rf feeds/luci/{applications,collections,protocols,themes,libs,docs,contrib}
rm -Rf feeds/luci/modules/!(luci-base)
rm -Rf feeds/packages/!(lang|libs|devel|utils|net|multimedia)
rm -Rf feeds/packages/multimedia/!(gstreamer1)
rm -Rf feeds/packages/net/!(mosquitto|curl|unbound)
rm -Rf feeds/packages/lang/{php*,ruby,perl}
rm -Rf feeds/packages/utils/!(tar|xz|docker|dockerd|containerd|zstd|unzip|acl|lm-sensors|xxhash|runc|tini)
rm -Rf feeds/base_root/package/firmware
rm -Rf feeds/base_root/package/network/!(services|utils)
rm -Rf feeds/base_root/package/network/services/!(ppp)
rm -Rf feeds/base_root/package/system/!(opkg|ubus|uci|ca-certificates)
rm -Rf feeds/base_root/package/kernel/!(cryptodev-linux||bpf-headers|mac80211)
#COMMENT

status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/mgz0227/OP-Packages/actions/runs" | jq -r '.workflow_runs[0].status')
while [[ "$status" == "in_progress" || "$status" == "queued" ]];do
echo "wait 5s"
sleep 5
status=$(curl -H "Authorization: token $REPO_TOKEN" -s "https://api.github.com/repos/mgz0227/OP-Packages/actions/runs" | jq -r '.workflow_runs[0].status')
done

./scripts/feeds update -a
./scripts/feeds install -a -p miaogongzi -f
./scripts/feeds install -a

rm -rf package/feeds/miaogongzi/luci-app-quickstart/root/usr/share/luci/menu.d/luci-app-quickstart.json

sed -i 's/\(page\|e\)\?.acl_depends.*\?}//' `find package/feeds/miaogongzi/luci-*/luasrc/controller/* -name "*.lua"`

sed -i "s#false; \\\#true; \\\#" include/download.mk

sed -i \
	-e "s/+\(luci\|luci-ssl\|uhttpd\)\( \|$\)/\2/" \
	-e "s/+nginx\( \|$\)/+nginx-ssl\1/" \
	-e 's/+python\( \|$\)/+python3/' \
	-e 's?../../lang?$(TOPDIR)/feeds/packages/lang?' \
	-e 's,$(STAGING_DIR_HOST)/bin/upx,upx,' \
	package/feeds/miaogongzi/*/Makefile

cp -f devices/common/.config .config

sed -i '/WARNING: Makefile/d' scripts/package-metadata.pl


cp -f devices/common/po2lmo staging_dir/host/bin/po2lmo
chmod +x staging_dir/host/bin/po2lmo