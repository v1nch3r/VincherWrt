#!/bin/sh
#==========================================================

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

clash="https://github.com/Dreamacro/clash/releases/download/v1.14.0/clash-linux-amd64-v1.14.0.gz"
clash_tun="https://release.dreamacro.workers.dev/2023.03.18/clash-linux-amd64-2023.03.18.gz"
clash_meta="https://github.com/djoeni/Clash.Meta/releases/download/Prerelease-WSS/Clash.Meta-linux-amd64-compatible-36e3318.gz"
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

add_clash_core () {
    mkdir -p ${imagebuilder_path}/files/etc/openclash/core/ && cd ${imagebuilder_path}/files/etc/openclash/core/
    wget ${clash} && gunzip *.gz || error_msg
    mv -f clash-* clash && rm -f *.gz
    wget ${clash_tun} && gunzip *.gz || error_msg
    mv -f clash-* clash_tun && rm -f *.gz
    wget ${clash_meta} && gunzip *.gz || error_msg
    mv -f Clash.* clash_meta && rm -f *.gz
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
}

add_clash_core
add_custom_file

exit 0