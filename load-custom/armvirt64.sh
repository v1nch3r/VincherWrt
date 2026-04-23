#!/bin/sh
#==========================================================
# VincherWrt - Custom Files for armvirt64 (Amlogic)
#==========================================================

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

# Clash cores for ARM64 (use MetaCubeX mihomo for reliability)
clash="https://github.com/Kuingsmile/clash-core/releases/download/1.18/clash-linux-arm64-v1.18.0.gz"
clash_meta="https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-arm64-v1.19.24.gz"

# Other downloads
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"

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
    if retry_download "${clash}" "clash.tar.gz"; then
        tar xzf *tar.gz
        mv -f clash-* clash 2>/dev/null || true
        rm -f *tar.gz
    else
        echo "Warning: Failed to download clash core"
    fi
    
    # Download clash_meta (mihomo)
    if retry_download "${clash_meta}" "clash_meta.gz"; then
        gunzip -f *.gz
        mv -f mihomo* clash_meta 2>/dev/null || true
    else
        echo "Warning: Failed to download clash_meta core"
    fi
    
    rm -f *.gz *tar.gz 2>/dev/null || true
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
}

add_clash_core
add_custom_file

exit 0