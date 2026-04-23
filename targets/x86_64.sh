#!/bin/sh
#==========================================================
# VincherWrt Build Script - x86_64
#==========================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERROR="${RED}[ERROR]${NC}"
SUCCESS="${GREEN}[SUCCESS]${NC}"
INFO="${YELLOW}[INFO]${NC}"

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

# targets
releases="$(cat "${make_path}/openwrt-version.txt")"
targets="x86/64"

# repository
imagebuilder_repo="https://downloads.openwrt.org/releases/${releases}/targets/${targets}/openwrt-imagebuilder-${releases}-x86-64.Linux-x86_64.tar.zst"

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
    local max_retries=3
    local retry=1
    
    while [ $retry -le $max_retries ]; do
        log "Download attempt $retry/$max_retries: $(basename $url)"
        if wget -q -O "/tmp/$(basename $url)" "${url}"; then
            mv "/tmp/$(basename $url)" "./$(basename $url)"
            success_msg "Downloaded: $(basename $url)"
            return 0
        fi
        log "Retry $retry/$max_retries for $(basename $url)"
        retry=$((retry + 1))
        sleep 3
    done
    error_msg "Failed to download after $max_retries attempts: $url"
}

download_imagebuilder() {
    log "Downloading ImageBuilder for ${releases}..."
    log "URL: ${imagebuilder_repo}"
    
    # Clean previous
    rm -rf ${openwrt_dir} openwrt-imagebuilder-*.tar.zst 2>/dev/null || true
    
    # Download with retry
    if ! retry_download "${imagebuilder_repo}"; then
        error_msg "Failed to download ImageBuilder"
    fi
    
    # Extract
    log "Extracting ImageBuilder..."
    tar -I zstd -xf openwrt-imagebuilder-*.tar.zst
    rm -f openwrt-imagebuilder-*.tar.zst
    mv -f openwrt-imagebuilder-* ${openwrt_dir}
    
    # Configure
    log "Configuring ImageBuilder..."
    sed -i "s|CONFIG_TARGET_ROOTFS_PARTSIZE=104|CONFIG_TARGET_ROOTFS_PARTSIZE=800|g" ${imagebuilder_path}/.config
    
    success_msg "ImageBuilder ready"
}

add_custom_packages() {
    log "Adding custom packages..."
    
    # Create local packages directory
    mkdir -p ${imagebuilder_path}/packages
    
    # Add x86_64 specific packages
    if [ -f "${make_path}/repository/target/x86_64.txt" ]; then
        log "Downloading x86_64 specific packages..."
        while IFS= read -r url; do
            [ -z "$url" ] && continue
            log "Downloading: $(basename $url)"
            wget -q -P ${imagebuilder_path}/packages/ "${url}" || log "Failed: $(basename $url)"
        done < "${make_path}/repository/target/x86_64.txt"
    fi
    
    # Add universal packages
    if [ -f "${make_path}/repository/target/universal.txt" ]; then
        log "Downloading universal packages..."
        while IFS= read -r url; do
            [ -z "$url" ] && continue
            log "Downloading: $(basename $url)"
            wget -q -P ${imagebuilder_path}/packages/ "${url}" || log "Failed: $(basename $url)"
        done < "${make_path}/repository/target/universal.txt"
    fi
    
    success_msg "Custom packages downloaded"
}

generate_package_index() {
    log "Generating local package index..."
    
    # Create Packages.gz for local packages
    cd ${imagebuilder_path}/packages
    if [ -f Packages ]; then
        rm -f Packages.gz
    fi
    
    # Generate Packages file from all .ipk files
    for ipk in *.ipk; do
        [ -f "$ipk" ] || continue
        tar -xzf "$ipk" ./info.toml ./control 2>/dev/null || continue
        
        # Get package info
        if [ -f control ]; then
            Package=$(grep -m1 "^Package:" control | sed 's/^Package: //')
            Version=$(grep -m1 "^Version:" control | sed 's/^Version: //')
            Description=$(grep -m1 "^Description:" control | sed 's/^Description: //')
            Architecture=$(grep -m1 "^Architecture:" control | sed 's/^Architecture: //')
            Filename="$ipk"
            Size=$(stat -c%s "$ipk" 2>/dev/null || echo "0")
            
            echo "Package: $Package" >> Packages
            echo "Version: $Version" >> Packages
            echo "Architecture: $Architecture" >> Packages
            echo "Filename: $Filename" >> Packages
            echo "Size: $Size" >> Packages
            echo "Description: $Description" >> Packages
            echo "" >> Packages
        fi
        
        rm -f control info.toml 2>/dev/null || true
    done
    
    # Compress Packages
    if [ -f Packages ]; then
        gzip -9 Packages
        success_msg "Package index generated"
    else
        log "Warning: No packages found to index"
    fi
    
    cd ${make_path}
}

run_custom_scripts() {
    log "Running custom load script..."
    
    if [ -f "${make_path}/load-custom/x86_64.sh" ]; then
        # Copy custom files to imagebuilder
        sh ${make_path}/load-custom/x86_64.sh || log "Custom script had warnings"
        success_msg "Custom scripts executed"
    fi
}

build_rootfs() {
    log "Building rootfs..."
    
    local my_packages="$(cat "${make_path}/packages.txt")"
    local package_count=$(echo $my_packages | wc -w)
    log "Installing $package_count packages..."
    
    cd ${imagebuilder_path}
    
    # Add local packages repo to opkg.conf
    echo "src/gz custom_local file:packages" >> ${imagebuilder_path}/repositories.conf
    
    # Build image with local packages
    make image PROFILE="generic" PACKAGES="${my_packages}" FILES="files"
    
    success_msg "Rootfs built successfully"
}

# Main
log "=== VincherWrt Build for x86_64 ==="
log "OpenWrt Version: ${releases}"

download_imagebuilder
add_custom_packages
generate_package_index
run_custom_scripts
build_rootfs

success_msg "=== Build Complete ==="
exit 0