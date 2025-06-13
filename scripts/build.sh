#!/bin/bash

# Check if at least one argument is provided
if [ "$#" -lt 2 ]; then
    echo "Error: At least 2 arguments are required."
    exit 1
fi
android="${1}"
device="${2}"

ksu_variant=""
if [ "$#" -ge 3 ]; then
    ksu_variant="${3}"
fi

ksu_branch="stable"
if [ "$#" -ge 4 ]; then
    ksu_branch="${4}"
fi

# my repo containing patches and scripts
build_utils="https://raw.githubusercontent.com/SomeEmptyBox/android_build_utils/refs/heads/main"

# Function for centralized error handling
handle_error() {
    local error_message="$1"
    echo "Error: ${error_message}."
    exit 1
}

cleanup() {
    echo "Cleaning up..."
    for patch in "${patches[@]}"; do
        patch_url="${build_utils}/patches/${patch}.patch"
        echo "Processing reverse patch: ${patch} from ${patch_url}"

        if grep -q "Reversed (or previously applied) patch detected!" <(curl -fLSs "${patch_url}" | patch --dry-run --strip 1 --fuzz 3 2>&1); then
            echo "Attempting to reverse ${patch} patch..."
            curl -fLSs "${patch_url}" | patch --strip 1 --fuzz 3 --reverse || handle_error "Failed to reverse ${patch} patch"
            echo "${patch} patch reversed successfully."
        else
            echo "${patch} patch has not been applied. Skipping."
        fi
        echo
    done
    rm -rf {device,vendor,kernel,hardware}/motorola vendor/private .repo/local_manifests
    unset GH_TOKEN
    echo "Exiting."
}

set -o pipefail
trap 'handle_error "An unexpected error occurred"' ERR
trap 'cleanup' EXIT

echo
echo "============================"
echo "Sync ROM and device sources."
echo "============================"
echo

# crave resync script
local_script="/opt/crave/resync.sh"
remote_script="${build_utils}/scripts/resync.sh"

# Initialize ROM and Device source
case "${android}" in
    "lineage")
        repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs || handle_error "Repo init failed"
        ;;
    "evolution")
        repo init -u https://github.com/Evolution-X/manifest -b vic --git-lfs || handle_error "Repo init failed"
        ;;
    "rising")
        repo init -u https://github.com/RisingOS-Revived/android -b qpr2 --git-lfs || handle_error "Repo init failed"
        ;;
    "matrixx")
        repo init -u https://github.com/ProjectMatrixx/android.git -b 15.0 --git-lfs || handle_error "Repo init failed"
        ;;
    "pixel")
        repo init -u https://github.com/PixelOS-AOSP/manifest.git -b fifteen --git-lfs || handle_error "Repo init failed"
        ;;
    "infinity")
        repo init --depth=1 --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 15 -g default,-mips,-darwin,-notdefault || handle_error "Repo init failed"
        ;;
    *)
        handle_error "Invalid option: ${android}. Use lineage, evolution, or rising"
        ;;
esac
curl -fLSs --create-dirs "${build_utils}/manifests/${device}.xml" -o .repo/local_manifests/default.xml || handle_error "Local manifest init failed"
git clone https://${GH_TOKEN}@github.com/SomeEmptyBox/android_vendor_private_keys vendor/private/keys || handle_error "cloning keys failed"

# check if local sync script exists. if not, use remote sync script
if [ -f "${local_script}" ]; then
    echo "Attempting to run local sync script: ${local_script}"
    "${local_script}" || handle_error "Local sync script execution failed"
else
    echo "Local sync script (${local_script}) not found."
    echo "Attempting to download and run remote sync script from: ${remote_script}"
    curl -fLSs "${remote_script}" | bash || handle_error "Remote sync script download or execution failed"
fi

echo
echo "===================================="
echo "Sync process completed successfully."
echo "===================================="
echo

# Root using KernelSU or KernelSU Next
# SuSFS patched
# Requires two arguments
# 1. ksu_variant: ksu or next
# 2. ksu_branch: stable or dev
if [ "$#" -ge 3 ]; then
    curl -fLSs ${build_utils}/scripts/root.sh | bash -s ${ksu_variant} ${ksu_branch}
fi

echo
echo "================="
echo "Applying patches."
echo "================="
echo

# Apply patches
patches=(
    "${android}"
    "telephony"
    "vibrator"
    "misc_kernel"
    "temp"
)

for patch in "${patches[@]}"; do
    patch_url="${build_utils}/patches/${patch}.patch"
    echo "Processing patch: ${patch} from ${patch_url}"

    if ! grep -q "Reversed (or previously applied) patch detected!" <(curl -fLSs "${patch_url}" | patch --dry-run --strip 1 --fuzz 3 2>&1); then
        echo "Attempting to apply ${patch} patch..."
        curl -fLSs "${patch_url}" | patch --strip 1 --fuzz 3 || handle_error "Failed to apply ${patch} patch"
        echo "${patch} patch applied successfully."
    else
        echo "${patch} patch has already been applied. Skipping."
    fi
    echo
done

echo
echo "================================="
echo "All patches applied successfully."
echo "================================="
echo



echo
echo "======================="
echo "Starting build process."
echo "======================="
echo

echo "Exporting important variables..."
export BUILD_USERNAME="peace"
export BUILD_HOSTNAME="crave"
export KBUILD_BUILD_USER="peace"
export KBUILD_BUILD_HOST="crave"
export TZ="Asia/Kolkata"
export TARGET_HAS_UDFPS=true
export DISABLE_ARTIFACT_PATH_REQUIREMENTS=true

echo "Starting build process..."
source build/envsetup.sh
lunch infinity_eqe-user
mka bacon

echo "Uploading file..."
curl ${build_utils}/scripts/upload.sh | bash -s ${OUT}/{*.zip,recovery.img,vendor_boot.img}

echo
echo "============================="
echo "Build completed successfully."
echo "============================="
echo
