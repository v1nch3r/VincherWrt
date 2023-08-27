#!/bin/sh
#==========================================================

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

clash="https://github.com/Dreamacro/clash/releases/download/v1.16.0/clash-linux-arm64-v1.16.0.gz"
clash_tun="https://release.dreamacro.workers.dev/2023.05.19/clash-linux-arm64-2023.05.19.gz"
clash_meta="https://github.com/djoeni/Clash.Meta/releases/download/Prerelease-WSS/Clash.Meta-linux-arm64-36e3318.gz"
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

add_clash_core () {
    mkdir -p ${imagebuilder_path}/etc/openclash/core/ && cd ${imagebuilder_path}/etc/openclash/core/
    wget ${clash} && gunzip *.gz || error_msg
    mv -f clash-* clash && rm -f *.gz
    wget ${clash_tun} && gunzip *.gz || error_msg
    mv -f clash-* clash_tun && rm -f *.gz
    wget ${clash_meta} && gunzip *.gz || error_msg
    mv -f Clash.* clash_meta && rm -f *.gz
}

add_custom_file () {
    mkdir -p ${imagebuilder_path}/bin/
    wget -P ${make_path}/ ${speedtest_repo} || error_msg
    tar -xzvf ${make_path}/*.tgz -C ${imagebuilder_path}/bin/
    rm -f ${make_path}/*.tgz && rm -f ${imagebuilder_path}/bin/speedtest.*
    wget -P ${imagebuilder_path}/bin/ ${neofetch_repo} || error_msg
    unzip ${imagebuilder_path}/packages/passwall*.zip
}

add_clash_core
add_custom_file
exit 0
