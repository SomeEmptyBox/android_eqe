#!/bin/bash

function sync() {
    echo " "
    echo "===== sync rom ====="
    repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs
    curl "https://raw.githubusercontent.com/accupara/docker-images/refs/heads/master/aosp/common/resync.sh" | bash
    echo "===== apply patches ====="
    curl "https://raw.githubusercontent.com/SomeEmptyBox/android_eqe/refs/heads/main/telephony.patch" | patch --strip 1 --forward
    curl "https://raw.githubusercontent.com/SomeEmptyBox/android_eqe/refs/heads/main/vibrator.patch" | patch --strip 1 --forward
    echo "===== completed ====="
    echo " "
}

function clone() {
    echo " "
    echo "===== clone device ====="
    rm -rf {device,vendor,kernel,hardware}/motorola vendor/evolution-priv/keys
    git clone --branch lineage-22.2 https://github.com/SomeEmptyBox/android_device_motorola_eqe device/motorola/eqe
    git clone --depth 1 --branch lineage-22.2 https://github.com/SomeEmptyBox/android_hardware_motorola hardware/motorola
    git clone --depth 1 https://github.com/SomeEmptyBox/android_vendor_evolution-priv_keys vendor/evolution-priv/keys
    echo "===== switch ====="
    git config user.name "peace"
    git config user.email "peace@crave.com"
    cd device/motorola/eqe
    git checkout 241ce3ac00e6e94fba1c12645f4181eb6ceef3cc
    cd -
    echo "===== clone vendor ====="
    git clone --depth 1 --branch lineage-22.2 https://gitlab.com/moto-sm7550/proprietary_vendor_motorola_eqe vendor/motorola/eqe
    git clone --depth 1 https://gitlab.com/moto-sm7550/proprietary_vendor_motorola_eqe-motcamera vendor/motorola/eqe-motcamera
    echo "===== clone kernel ====="
    git clone --depth 1 https://github.com/moto-sm7550-devs/android_kernel_motorola_sm7550 kernel/motorola/sm7550
    git clone --depth 1 https://github.com/moto-sm7550-devs/android_kernel_motorola_sm7550-modules kernel/motorola/sm7550-modules
    git clone --depth 1 https://github.com/moto-sm7550-devs/android_kernel_motorola_sm7550-devicetrees kernel/motorola/sm7550-devicetrees
    echo "===== completed ====="
    echo " "
}

function root() {
    echo " "
    echo "===== integrate KernelSU Next with SUSFS and Wild Kernel patches ====="
    cd kernel/motorola/sm7550

    # KernelSU Next
    curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs

    # SUSFS patches for Kernel
    git clone -b gki-android13-5.15 https://gitlab.com/simonpunk/susfs4ksu susfs
    cp ./susfs/kernel_patches/50_add_susfs_in_gki-android13-5.15.patch .
    cp ./susfs/kernel_patches/fs/* fs
    cp ./susfs/kernel_patches/include/linux/* include/linux
    patch -p1 --fuzz=3 <50_add_susfs_in_gki-android13-5.15.patch

    # Wild kernel patches
    curl "https://raw.githubusercontent.com/WildKernels/kernel_patches/refs/heads/main/next/syscall_hooks.patch" | patch -p1 --fuzz=3
    curl "https://raw.githubusercontent.com/WildKernels/kernel_patches/refs/heads/main/69_hide_stuff.patch" | patch -p1 --fuzz=3

    # SUSFS backport patch
    curl "https://raw.githubusercontent.com/SomeEmptyBox/android_eqe/refs/heads/main/susfs_backport.patch" | patch -p1 --fuzz=3

    # Add configuration settings to gki_defconfig
    echo "CONFIG_KSU=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_KPROBES_HOOK=n" >> ./arch/arm64/configs/gki_defconfig

    # Add tmpfs config setting
    echo "CONFIG_TMPFS_XATTR=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_TMPFS_POSIX_ACL=y" >> ./arch/arm64/configs/gki_defconfig

    # Add additional config setting
    echo "CONFIG_IP_NF_TARGET_TTL=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_IP6_NF_TARGET_HL=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_IP6_NF_MATCH_HL=y" >> ./arch/arm64/configs/gki_defconfig

    # Add BBR Config
    echo "CONFIG_TCP_CONG_ADVANCED=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_TCP_CONG_BBR=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_NET_SCH_FQ=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_TCP_CONG_BIC=n" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_TCP_CONG_WESTWOOD=n" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_TCP_CONG_HTCP=n" >> ./arch/arm64/configs/gki_defconfig

    # Add SUSFS configuration settings
    echo "CONFIG_KSU_SUSFS=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SUS_PATH=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" >> ./arch/arm64/configs/gki_defconfig
    echo "CONFIG_KSU_SUSFS_SUS_SU=n" >> ./arch/arm64/configs/gki_defconfig

    # Some random fixes
    sed -i 's/check_defconfig//' ./build.config.gki
    sed -i 's/-dirty/-peace/g' ./scripts/setlocalversion
    sed -i '2435s/timestamp/*timestamp/g' ./include/uapi/linux/videodev2.h

    cd -
    echo "===== completed ====="
    echo " "
}

function build() {
    echo " "
    echo "===== start build ====="
    export BUILD_USERNAME="peace"
    export BUILD_HOSTNAME="crave"
    export KBUILD_BUILD_USER="peace"
    export KBUILD_BUILD_HOST="crave"
    export TZ="Asia/Kolkata"
    export TARGET_HAS_UDFPS=true
    export TARGET_INCLUDE_ACCORD=false
    export DISABLE_ARTIFACT_PATH_REQUIREMENTS=true
    source build/envsetup.sh
    lunch lineage_eqe-bp1a-user
    make installclean
    m evolution
    curl "https://raw.githubusercontent.com/SomeEmptyBox/android_eqe/refs/heads/main/upload.sh" | bash -s out/target/product/eqe/{*.zip,boot.img,init_boot.img,vendor_boot.img,recovery.img,eqe.json}
    echo "===== completed ====="
    echo " "
}

# Check if at least one argument is passed
if [ $# -lt 1 ]; then
    echo "Usage: $0 <option(s)>"
    echo "Options:"
    echo "  sync   - sync rom source"
    echo "  clone  - clone device source"
    echo "  root   - integrate KernelSU Next + SuSFS"
    echo "  build  - start building"
    exit 1
fi

# Loop through all arguments and run the corresponding functions
for arg in "$@"; do
    case $arg in
        sync)
            sync
            ;;
        clone)
            clone
            ;;
        root)
            root
            ;;
        build)
            build
            ;;
        *)
            echo "Invalid option: $arg"
            ;;
    esac
done
