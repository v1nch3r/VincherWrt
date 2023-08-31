#!/bin/sh
#==========================================================

# dir path
make_path="$(pwd)"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"

# targets
releases="$(cat "${make_path}/openwrt-version.txt")"
targets="x86/64"

# repository
imagebuilder_repo="https://downloads.openwrt.org/releases/${releases}/targets/${targets}/openwrt-imagebuilder-${releases}-x86-64.Linux-x86_64.tar.xz"

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

download_imagebuilder () {
    wget ${imagebuilder_repo} || error_msg
    tar -xJf openwrt-imagebuilder-* && rm -f openwrt-imagebuilder-*.tar.xz
    mv -f openwrt-imagebuilder-* ${openwrt_dir}
#    mv -f custom-files/repositories.conf ${imagebuilder_path}
    sed -i "s|CONFIG_TARGET_ROOTFS_PARTSIZE=104|CONFIG_TARGET_ROOTFS_PARTSIZE=800|g" ${imagebuilder_path}/.config || error_msg
}

add_custom_file () {
## add x86_64 package
    wget -P ${imagebuilder_path}/packages/ -i ${make_path}/repository/target/x86_64.txt || error_msg 
## add universal package
    wget -P ${imagebuilder_path}/packages/ -i ${make_path}/repository/target/universal.txt || error_msg
## load custom
    sh ${make_path}/load-custom/x86_64.sh || error_msg
}

build_rootfs () {
    my_packages="$(cat "${make_path}/universal.txt")"
    cd ${imagebuilder_path}
    make image PROFILE="generic" PACKAGES="${my_packages}" FILES="files" || error_msg
}

download_imagebuilder
add_custom_file
build_rootfs
exit 0