fetch() {
    local name="$1"
    local url="$2"

    echo "Fetching ${name} from ${url}..."
    curl -fLSs "${url}" -o "../${name}"

    if [ $? -eq 0 ]; then
        echo "File saved as ${name}"
    else
        echo "Failed to fetch the file from ${url}"
    fi
}

fetch "patches/susfs_ksu.patch"         "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android13-5.15/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch?ref_type=heads"
fetch "patches/susfs_kernel.patch"      "https://gitlab.com/simonpunk/susfs4ksu/-/raw/gki-android13-5.15/kernel_patches/50_add_susfs_in_gki-android13-5.15.patch?ref_type=heads"
fetch "patches/hide_stuff.patch"        "https://raw.githubusercontent.com/WildKernels/kernel_patches/refs/heads/main/69_hide_stuff.patch"
fetch "patches/syscall_hooks.patch"     "https://raw.githubusercontent.com/WildKernels/kernel_patches/refs/heads/main/next/syscall_hooks.patch"

fetch "scripts/resync.sh"               "https://raw.githubusercontent.com/accupara/docker-images/refs/heads/master/aosp/common/resync.sh"
fetch "scripts/upload.sh"               "https://raw.githubusercontent.com/Drenzzz/script-upload/refs/heads/master/upload.sh"
