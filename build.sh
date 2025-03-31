#!/bin/bash

function sync() {
    echo " "
    echo "===== sync rom ====="
    repo init -u https://github.com/ProjectMatrixx/android.git -b 15.0-old --git-lfs
    /opt/crave/resync.sh
    echo "===== apply patches ====="
    rm -rf packages/services/Telephony vendor/qcom/opensource/vibrator
    git clone https://github.com/SomeEmptyBox/android_packages_services_Telephony packages/services/Telephony
    git clone https://github.com/moto-sm7550-devs/android_vendor_qcom_opensource_vibrator vendor/qcom/opensource/vibrator
    echo "===== completed ====="
    echo " "
}

function clone() {
    echo " "
    echo "===== clone device ====="
    rm -rf {device,vendor,kernel,hardware}/motorola vendor/evolution-priv/keys system/qcom
    git clone --depth 1 -b matrixx https://github.com/SomeEmptyBox/android_device_motorola_eqe device/motorola/eqe
    git clone --depth 1 https://github.com/moto-sm7550-devs/android_hardware_motorola hardware/motorola
    git clone --depth 1 https://github.com/LineageOS/android_system_qcom system/qcom
    git clone --depth 1 https://github.com/SomeEmptyBox/vendor_evolution-priv_keys vendor/lineage-priv/keys
    echo "===== clone vendor ====="
    git clone --depth 1 https://gitlab.com/moto-sm7550/proprietary_vendor_motorola_eqe vendor/motorola/eqe
    git clone --depth 1 https://gitlab.com/moto-sm7550/proprietary_vendor_motorola_eqe-motcamera vendor/motorola/eqe-motcamera
    echo "===== clone kernel ====="
    git clone --depth 1 https://github.com/SomeEmptyBox/android_kernel_motorola_sm7550 kernel/motorola/sm7550
    git clone --depth 1 https://github.com/moto-sm7550-devs/android_kernel_motorola_sm7550-modules kernel/motorola/sm7550-modules
    git clone --depth 1 https://github.com/moto-sm7550-devs/android_kernel_motorola_sm7550-devicetrees kernel/motorola/sm7550-devicetrees
    echo "===== completed ====="
    echo " "
}

function root() {
    echo " "
    echo "===== integrate KernelSU Next + SuSFS ====="
    cd kernel/motorola/sm7550
    curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs
    git clone -b gki-android13-5.15 https://gitlab.com/simonpunk/susfs4ksu susfs
    cp ./susfs/kernel_patches/50_add_susfs_in_gki-android13-5.15.patch .
    cp ./susfs/kernel_patches/fs/* fs
    cp ./susfs/kernel_patches/include/linux/* include/linux
    patch -p1 < 50_add_susfs_in_gki-android13-5.15.patch
    cd -
    echo "===== completed ====="
    echo " "
}

function build() {
    echo " "
    echo "===== start build ====="
    export BUILD_USERNAME=peace
    export BUILD_HOSTNAME=crave
    export TARGET_HAS_UDFPS=true
    export WITH_GMS=true
    export TARGET_SUPPORTS_GSUITE=true
    export TARGET_SUPPORTS_GOOGLE_RECORDER=true
    export DISABLE_ARTIFACT_PATH_REQUIREMENTS=true
    source build/envsetup.sh
    brunch eqe
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
