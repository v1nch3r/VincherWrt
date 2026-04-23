#!/bin/sh
#==========================================================
# VincherWrt - Custom Files for x86_64
#==========================================================

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

# PassWall packages (additional dependencies for PassWall2)
passwall_packages_url="https://github.com/Openwrt-Passwall/openwrt-passwall2/releases/download/26.4.10-1/passwall_packages_apk_x86_64.zip"

# Clash cores
clash_core="https://github.com/Kuingsmile/clash-core/releases/download/1.18/clash-linux-amd64-v1.18.0.gz"

# Other downloads
speedtest_repo="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
neofetch_repo="https://raw.githubusercontent.com/dylanaraps/neofetch/master/neofetch"
custom_banner="https://raw.githubusercontent.com/v1nch3r/amlogic-openwrt/main/make-openwrt/openwrt-files/common-files/etc/banner"
mac80211="https://raw.githubusercontent.com/v1nch3r/openwrt/openwrt-21.02/package/kernel/mac80211/files/lib/wifi/mac80211.sh"

log() {
    echo -e "${INFO} $1"
}

error_msg() {
    echo -e "${ERROR} $1"
    exit 1
}

success_msg() {
    echo -e "${SUCCESS} $1"
}

retry_download() {
    local url="$1"
    local dest="$2"
    local max_retries=5
    local retry=1
    local wait=5
    
    while [ $retry -le $max_retries ]; do
        log "[$retry/$max_retries] Downloading: $(basename "$url")"
        if wget -q -L --no-check-certificate -O "$dest" "$url"; then
            if [ -s "$dest" ]; then
                success_msg "Downloaded: $(basename "$url")"
                return 0
            fi
        fi
        log "Retry $retry/$max_retries for $(basename "$url")"
        retry=$((retry + 1))
        sleep $wait
        wait=$((wait * 2))
    done
    return 1
}

add_passwall_packages() {
    log "Downloading PassWall packages..."
    
    local zip_file="/tmp/passwall_packages.zip"
    local extract_dir="/tmp/passwall_packages"
    
    if retry_download "$passwall_packages_url" "$zip_file"; then
        mkdir -p "$extract_dir"
        unzip -o "$zip_file" -d "$extract_dir"
        
        # Move all .apk files to packages directory
        mkdir -p "${imagebuilder_path}/packages"
        mv "$extract_dir"/*.apk "${imagebuilder_path}/packages/" 2>/dev/null || true
        
        log "PassWall packages added:"
        ls -la "${imagebuilder_path}/packages/"*.apk 2>/dev/null || log "No .apk files found"
        
        # Cleanup
        rm -rf "$zip_file" "$extract_dir"
        
        success_msg "PassWall packages extracted to packages/"
    else
        log "Warning: Failed to download PassWall packages"
    fi
}

add_clash_core() {
    log "Downloading Clash cores..."
    mkdir -p "${imagebuilder_path}/files/etc/openclash/core/"
    cd "${imagebuilder_path}/files/etc/openclash/core/" || exit 1
    
    # Download clash (regular core)
    if retry_download "${clash_core}" "clash.gz"; then
        gunzip -f *.gz
        mv -f clash-* clash 2>/dev/null || true
        # Copy as clash_tun as fallback (if premium not available)
        [ -f clash ] && cp clash clash_tun
    else
        log "Warning: Failed to download clash core"
    fi
    
    rm -f *.gz 2>/dev/null || true
    
    cd ${make_path}
}

add_custom_file() {
    log "Downloading custom files..."
    
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

# Main
add_passwall_packages
add_clash_core
add_custom_file

exit 0