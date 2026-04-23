#!/bin/sh
#==========================================================
# VincherWrt - Load Custom Files for x86_64
#==========================================================

set -e

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

# URLs
clash="https://github.com/Kuingsmile/clash-core/releases/download/v1.18.0/clash-linux-amd64-v1.18.0.gz"
clash_tun="https://github.com/Kuingsmile/clash-core/releases/download/premium/clash-linux-amd64-2023.08.17.gz"
clash_meta="https://github.com/djoeni/Clash.Meta/releases/download/Prerelease-WSS/Clash.Meta-linux-amd64-compatible-36e3318.gz"
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"
custom_banner="https://raw.githubusercontent.com/v1nch3r/amlogic-openwrt/main/make-openwrt/openwrt-files/common-files/etc/banner"
mac80211="https://raw.githubusercontent.com/v1nch3r/openwrt/openwrt-21.02/package/kernel/mac80211/files/lib/wifi/mac80211.sh"

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
    log "Adding Clash cores..."
    
    local core_dir="${imagebuilder_path}/files/etc/openclash/core"
    mkdir -p "$core_dir"
    cd "$core_dir"
    
    # Download Clash
    if download "$clash" "clash.gz"; then
        gunzip -f *.gz 2>/dev/null || true
        mv -f clash-* clash 2>/dev/null || true
        rm -f *.gz
    else
        echo "Warning: Failed to download Clash"
    fi
    
    # Download Clash TUN
    if download "$clash_tun" "clash_tun.gz"; then
        gunzip -f *.gz 2>/dev/null || true
        mv -f clash-* clash_tun 2>/dev/null || true
        rm -f *.gz
    else
        echo "Warning: Failed to download Clash TUN"
    fi
    
    # Download Clash Meta
    if download "$clash_meta" "clash_meta.gz"; then
        gunzip -f *.gz 2>/dev/null || true
        mv -f Clash.* clash_meta 2>/dev/null || true
        rm -f *.gz
    else
        echo "Warning: Failed to download Clash Meta"
    fi
    
    log "Clash cores added"
}

add_custom_files() {
    log "Adding custom files..."
    
    # Speedtest
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
    
    # Custom banner
    if download "$custom_banner" "${imagebuilder_path}/files/etc/banner"; then
        log "Banner added"
    fi
    
    # Scripts to uci-defaults
    if [ -d "${make_path}/scripts" ]; then
        mkdir -p ${imagebuilder_path}/files/etc/uci-defaults
        cp -f ${make_path}/scripts/* ${imagebuilder_path}/files/etc/uci-defaults/ 2>/dev/null || true
    fi
    
    # Custom mac80211
    mkdir -p ${imagebuilder_path}/files/lib/wifi
    download "$mac80211" "${imagebuilder_path}/files/lib/wifi/mac80211.sh"
    
    # Unzip passwall packages if exists
    if ls ${imagebuilder_path}/packages/passwall*.zip 1>/dev/null 2>&1; then
        unzip -o ${imagebuilder_path}/packages/passwall*.zip -d ${imagebuilder_path}/packages/ 2>/dev/null || true
    fi
    
    log "Custom files added"
}

# Main
log "=== Load Custom Files for x86_64 ==="
add_clash_core
add_custom_files
log "=== Done ==="
