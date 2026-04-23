#!/bin/sh
#==========================================================
# VincherWrt - Build OpenWrt armvirt64 Image
#==========================================================

set -e  # Exit on error

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
log_file="${make_path}/build.log"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# targets
releases="$(cat "${make_path}/openwrt-version.txt")"
targets="armsr"

# repository (OpenWrt uses .tar.zst for armsr)
imagebuilder_repo="https://downloads.openwrt.org/releases/${releases}/targets/${targets}/armv8/openwrt-imagebuilder-${releases}-${targets}-armv8.Linux-x86_64.tar.zst"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

error_msg() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$log_file"
    exit 1
}

success_msg() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$log_file"
}

# Check prerequisites
check_prereq() {
    log "Checking prerequisites..."
    command -v wget >/dev/null 2>&1 || error_msg "wget is required"
    command -v tar >/dev/null 2>&1 || error_msg "tar is required"
    command -v zstd >/dev/null 2>&1 || error_msg "zstd is required (apt install zstd)"
    success_msg "Prerequisites OK"
}

download_imagebuilder() {
    log "Downloading OpenWrt ImageBuilder for armvirt64..."
    
    if [ -d "${openwrt_dir}" ]; then
        log "Removing old imagebuilder..."
        rm -rf ${openwrt_dir}
    fi
    
    wget --show-progress -O openwrt-imagebuilder.tar.zst "${imagebuilder_repo}" >> "$log_file" 2>&1 || error_msg "Failed to download ImageBuilder"
    
    log "Extracting ImageBuilder..."
    tar -I zstd -xf openwrt-imagebuilder.tar.zst >> "$log_file" 2>&1 || error_msg "Failed to extract ImageBuilder"
    rm -f openwrt-imagebuilder.tar.zst
    
    mv -f openwrt-imagebuilder-* ${openwrt_dir}
    
    # Increase rootfs size to 800MB
    sed -i "s|CONFIG_TARGET_ROOTFS_PARTSIZE=104|CONFIG_TARGET_ROOTFS_PARTSIZE=800|g" ${imagebuilder_path}/.config
    
    # Disable uqmi package (not needed for armvirt)
    sed -i "s|CONFIG_PACKAGE_uqmi=m|CONFIG_PACKAGE_uqmi=n|g" ${imagebuilder_path}/.config
    
    success_msg "ImageBuilder ready"
}

add_packages() {
    log "Adding packages..."
    
    mkdir -p ${imagebuilder_path}/packages
    
    # Download armvirt64 specific packages
    if [ -f "${make_path}/repository/target/armvirt64.txt" ]; then
        log "Downloading armvirt64 packages..."
        wget -q -P ${imagebuilder_path}/packages/ -i ${make_path}/repository/target/armvirt64.txt >> "$log_file" 2>&1 || error_msg "Failed to download armvirt64 packages"
    fi
    
    # Download universal packages
    if [ -f "${make_path}/repository/target/universal.txt" ]; then
        log "Downloading universal packages..."
        wget -q -P ${imagebuilder_path}/packages/ -i ${make_path}/repository/target/universal.txt >> "$log_file" 2>&1 || error_msg "Failed to download universal packages"
    fi
    
    success_msg "Packages added"
}

add_custom_files() {
    log "Adding custom files and scripts..."
    
    # Execute load-custom script
    if [ -f "${make_path}/load-custom/armvirt64.sh" ]; then
        sh ${make_path}/load-custom/armvirt64.sh >> "$log_file" 2>&1 || error_msg "Failed to execute load-custom/armvirt64.sh"
    fi
    
    success_msg "Custom files added"
}

build_image() {
    log "Building armvirt64 rootfs image..."
    
    # Create FILES directory if not exists
    mkdir -p ${imagebuilder_path}/files
    
    cd ${imagebuilder_path}
    
    # Get packages from universal.txt
    my_packages="$(cat "${make_path}/universal.txt")"
    
    # Build image
    make image PROFILE="generic" PACKAGES="${my_packages}" FILES="files" >> "$log_file" 2>&1 || error_msg "Build failed"
    
    # Relocate rootfs to amlogic-openwrt directory
    log "Relocating rootfs..."
    mkdir -p ${make_path}/amlogic-openwrt/openwrt-armvirt
    find ${imagebuilder_path}/bin/targets/*/*/ -type f -name '*rootfs.tar.gz' -exec mv -t ${make_path}/amlogic-openwrt/openwrt-armvirt/ {} +
    
    success_msg "Image built successfully!"
    log "Output: ${make_path}/amlogic-openwrt/openwrt-armvirt/"
}

# Main execution
main() {
    log "=== VincherWrt Build Started ==="
    log "OpenWrt Version: ${releases}"
    log "Target: armvirt64 (ARM Virtual)"
    
    check_prereq
    download_imagebuilder
    add_packages
    add_custom_files
    build_image
    
    log "=== Build Completed ==="
}

main "$@"
