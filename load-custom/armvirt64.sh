#!/bin/sh
#==========================================================

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

clash="https://raw.githubusercontent.com/vernesong/OpenClash/refs/heads/core/master/dev/clash-linux-arm64.tar.gz"
clash_tun="https://raw.githubusercontent.com/vernesong/OpenClash/refs/heads/core/master/premium/clash-linux-arm64-2023.08.17-13-gdcc8d87.gz"
clash_meta="https://github.com/MetaCubeX/mihomo/releases/download/v1.18.10/mihomo-linux-arm64-v1.18.10.gz"
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"
# mac80211="https://raw.githubusercontent.com/v1nch3r/openwrt/openwrt-21.02/package/kernel/mac80211/files/lib/wifi/mac80211.sh"

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

add_clash_core () {
    mkdir -p ${imagebuilder_path}/files/etc/openclash/core/ && cd ${imagebuilder_path}/files/etc/openclash/core/
    # wget ${clash} && gunzip *.gz || error_msg
    # mv -f clash-* clash && rm -f *.gz
    wget ${clash} && tar xOvz *tar.gz || error_msg
    mv -f clash-* clash && rm -f *tar.gz
    wget ${clash_tun} && gunzip *.gz || error_msg
    mv -f clash-* clash_tun && rm -f *.gz
    wget ${clash_meta} && gunzip *.gz || error_msg
    mv -f mihomo.* clash_meta && rm -f *.gz
}

add_custom_file () {
    ## add speestest
    mkdir -p ${imagebuilder_path}/files/bin/
    wget -P ${make_path}/ ${speedtest_repo} || error_msg
    tar -xzvf ${make_path}/*.tgz -C ${imagebuilder_path}/files/bin/
    rm -f ${make_path}/*.tgz && rm -f ${imagebuilder_path}/files/bin/speedtest.*
    ## add neofetch
    wget -P ${imagebuilder_path}/files/bin/ ${neofetch_repo} || error_msg
    ## unzip passwall
    unzip ${imagebuilder_path}/packages/passwall*.zip -d ${imagebuilder_path}/packages/
    ## add scripts to uci-defaults
    mkdir -p ${imagebuilder_path}/files/etc/uci-defaults
    mv -f ${make_path}/scripts/* ${imagebuilder_path}/files/etc/uci-defaults/
    ## custom mac80211
    ## mkdir -p ${imagebuilder_path}/files/lib/wifi
    ## wget -P ${imagebuilder_path}/files/lib/wifi/ ${mac80211} || error_msg
}

add_clash_core
add_custom_file

exit 0