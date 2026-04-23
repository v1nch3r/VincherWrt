#!/bin/sh
#==========================================================
# VincherWrt - Load Custom Files for armvirt64
#==========================================================

set -e

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

# URLs - ARM64 cores
clash="https://raw.githubusercontent.com/vernesong/OpenClash/refs/heads/core/master/dev/clash-linux-arm64.tar.gz"
clash_tun="https://raw.githubusercontent.com/vernesong/OpenClash/refs/heads/core/master/premium/clash-linux-arm64-2023.08.17-13-gdcc8d87.gz"
clash_meta="https://github.com/MetaCubeX/mihomo/releases/download/v1.18.10/mihomo-linux-arm64-v1.18.10.gz"
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"

error_msg() {
    echo "[ERROR] $1" >&2
    exit 1
}

log() {
    echo "[INFO] $1"
}

# Download with retry
download() {
    local url="$1"
    local output="$2"
    local retries=3
    
    for i in $(seq 1 $retries); do
        if wget -q -O "$output" "$url" 2>/dev/null; then
            return 0
        fi
        echo "Retry $i/$retries for $url"
        sleep 2
    done
    return 1
}

add_clash_core() {
    log "Adding Clash cores for ARM64..."
    
    local core_dir="${imagebuilder_path}/files/etc/openclash/core"
    mkdir -p "$core_dir"
    cd "$core_dir"
    
    # Download Clash dev
    if download "$clash" "clash.tar.gz"; then
        tar -xzf *.tar.gz 2>/dev/null || gunzip -f *.gz 2>/dev/null || true
        mv -f clash-* clash 2>/dev/null || true
        rm -f *.tar.gz *.gz 2>/dev/null || true
    fi
    
    # Download Clash TUN
    if download "$clash_tun" "clash_tun.gz"; then
        gunzip -f *.gz 2>/dev/null || true
        mv -f clash-* clash_tun 2>/dev/null || true
        rm -f *.gz
    fi
    
    # Download Clash Meta (mihomo)
    if download "$clash_meta" "clash_meta.gz"; then
        gunzip -f *.gz 2>/dev/null || true
        mv -f mihomo.* clash_meta 2>/dev/null || true
        rm -f *.gz
    fi
    
    log "Clash cores added"
}

add_custom_files() {
    log "Adding custom files..."
    
    # Speedtest for ARM64
    local speedtest_dir="${imagebuilder_path}/files/bin"
    mkdir -p "$speedtest_dir"
    cd "$make_path"
    
    if download "$speedtest_repo" "speedtest.tgz"; then
        tar -xzf speedtest.tgz -C "$speedtest_dir/" 2>/dev/null || true
        rm -f speedtest.tgz
        rm -f ${speedtest_dir}/speedtest 2>/dev/null || true
    fi
    
    # Neofetch
    if download "$neofetch_repo" "${imagebuilder_path}/files/bin/neofetch"; then
        chmod +x ${imagebuilder_path}/files/bin/neofetch
    fi
    
    # Scripts to uci-defaults
    if [ -d "${make_path}/scripts" ]; then
        mkdir -p ${imagebuilder_path}/files/etc/uci-defaults
        cp -f ${make_path}/scripts/* ${imagebuilder_path}/files/etc/uci-defaults/ 2>/dev/null || true
    fi
    
    # Unzip passwall packages if exists
    if ls ${imagebuilder_path}/packages/passwall*.zip 1>/dev/null 2>&1; then
        unzip -o ${imagebuilder_path}/packages/passwall*.zip -d ${imagebuilder_path}/packages/ 2>/dev/null || true
    fi
    
    log "Custom files added"
}

# Main
log "=== Load Custom Files for armvirt64 ==="
add_clash_core
add_custom_files
log "=== Done ==="
