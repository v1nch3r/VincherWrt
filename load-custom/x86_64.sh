#!/bin/sh
#==========================================================

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

# Clash cores
clash="https://github.com/Kuingsmile/clash-core/releases/download/v1.18.0/clash-linux-amd64-v1.18.0.gz"
clash_tun="https://github.com/Kuingsmile/clash-core/releases/download/premium/clash-linux-amd64-2023.08.17.gz"
clash_meta="https://github.com/djoeni/Clash.Meta/releases/download/Prerelease-WSS/Clash.Meta-linux-amd64-compatible-36e3318.gz"

# Other downloads
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"
custom_banner="https://raw.githubusercontent.com/v1nch3r/amlogic-openwrt/main/make-openwrt/openwrt-files/common-files/etc/banner"
mac80211="https://raw.githubusercontent.com/v1nch3r/openwrt/openwrt-21.02/package/kernel/mac80211/files/lib/wifi/mac80211.sh"

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

retry_download() {
    local url="$1"
    local dest="$2"
    local max_retries=3
    local retry=1
    
    while [ $retry -le $max_retries ]; do
        if wget -q -O "${dest}" "${url}"; then
            return 0
        fi
        echo "Retry $retry/$max_retries for $url"
        retry=$((retry + 1))
        sleep 2
    done
    return 1
}

add_clash_core() {
    mkdir -p "${imagebuilder_path}/files/etc/openclash/core/"
    cd "${imagebuilder_path}/files/etc/openclash/core/" || exit 1
    
    # Download clash
    if ! retry_download "${clash}" "clash.gz"; then
        error_msg "Failed to download clash core"
    fi
    gunzip -f *.gz
    mv -f clash-* clash 2>/dev/null || true
    
    # Download clash_tun
    if ! retry_download "${clash_tun}" "clash_tun.gz"; then
        echo "Warning: Failed to download clash_tun core"
    else
        gunzip -f *.gz
        mv -f clash-* clash_tun 2>/dev/null || true
    fi
    
    # Download clash_meta
    if ! retry_download "${clash_meta}" "clash_meta.gz"; then
        echo "Warning: Failed to download clash_meta core"
    else
        gunzip -f *.gz
        mv -f Clash.* clash_meta 2>/dev/null || true
    fi
    
    rm -f *.gz 2>/dev/null || true
}

add_custom_file() {
    # Add speedtest
    mkdir -p "${imagebuilder_path}/files/bin/"
    if retry_download "${speedtest_repo}" "${make_path}/speedtest.tgz"; then
        tar -xzvf "${make_path}/speedtest.tgz" -C "${imagebuilder_path}/files/bin/" 2>/dev/null
        rm -f "${make_path}/speedtest.tgz"
        rm -f "${imagebuilder_path}/files/bin/speedtest"* 2>/dev/null || true
    fi
    
    # Add neofetch
    retry_download "${neofetch_repo}" "${imagebuilder_path}/files/bin/neofetch"
    chmod +x "${imagebuilder_path}/files/bin/neofetch"
    
    # Add scripts to uci-defaults
    mkdir -p "${imagebuilder_path}/files/etc/uci-defaults"
    if [ -d "${make_path}/scripts" ]; then
        mv -f "${make_path}"/scripts/* "${imagebuilder_path}/files/etc/uci-defaults/" 2>/dev/null || true
    fi
    
    # Add custom banner
    mkdir -p "${imagebuilder_path}/files/etc/"
    retry_download "${custom_banner}" "${imagebuilder_path}/files/etc/banner"
    
    # Add custom mac80211
    mkdir -p "${imagebuilder_path}/files/lib/wifi/"
    retry_download "${mac80211}" "${imagebuilder_path}/files/lib/wifi/mac80211.sh"
}

add_clash_core
add_custom_file

exit 0