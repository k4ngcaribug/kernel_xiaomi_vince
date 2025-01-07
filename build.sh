#!/bin/bash
#
# Compile script for AL kernel
# Copyright (C) 2020-2023 Adithya R.
# Copyright (C) 2024 AL

SECONDS=0 # builtin bash timer
ZIPNAME="AL-Kernel-EOL-Vince-$(TZ=Asia/Kolkata date +"%Y%m%d-%H%M").zip"
ZIPNAME_KSU="AL-Kernel-EOL-KSU-$(TZ=Asia/Kolkata date +"%Y%m%d-%H%M").zip"
TC_DIR="$HOME/tc/clang"
AK3_DIR="AnyKernel3"
DEFCONFIG="vince_defconfig"
export PATH="$TC_DIR/bin:$PATH"

# Build Environment
sudo apt update -y && sudo apt upgrade -y && sudo apt install nano bc bison ca-certificates curl flex gcc git libc6-dev libssl-dev openssl python-is-python3 ssh wget zip zstd sudo make clang gcc-arm-linux-gnueabi software-properties-common build-essential libarchive-tools gcc-aarch64-linux-gnu -y && sudo apt install build-essential -y && sudo apt install libssl-dev libffi-dev libncurses5-dev zlib1g zlib1g-dev libreadline-dev libbz2-dev libsqlite3-dev make gcc -y && sudo apt install pigz -y && sudo apt install python2 -y && sudo apt install python3 -y && sudo apt install cpio -y && sudo apt install lld -y && sudo apt install llvm -y

# Check for essentials
if ! [ -d "${TC_DIR}" ]; then
echo "Clang not found! Cloning to ${TC_DIR}..."
if ! git clone --depth=1 https://github.com/k4ngcaribug/aosp-clang -b main ${TC_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if [[ $1 = "-k" || $1 = "--ksu" ]]; then
	echo -e "\nCleanup KernelSU first on local build\n"
	rm -rf KernelSU drivers/kernelsu
else
	echo -e "\nSet No KernelSU Install, just skip\n"
fi

# Set function for override kernel name and variants
if [[ $1 = "-k" || $1 = "--ksu" ]]; then
echo -e "\nKSU Support, let's Make it On\n"
curl -kLSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -
sed -i 's/CONFIG_KSU=n/CONFIG_KSU=y/g' arch/arm64/configs/vince_defconfig
sed -i 's/CONFIG_LOCALVERSION="-AL-Kernel-EOL"/CONFIG_LOCALVERSION="-AL-Kernel-EOL-KSU"/g' arch/arm64/configs/vince_defconfig
else
echo -e "\nKSU not Support, let's Skip\n"
fi

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
exit
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) CC=clang CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- O=out ARCH=arm64

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout master &> /dev/null
if [[ $1 = "-k" || $1 = "--ksu" ]]; then
zip -r9 "../$ZIPNAME_KSU" * -x '*.git*' README.md *placeholder
else
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
fi
cd ..
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
if [[ $1 = "-k" || $1 = "--ksu" ]]; then
echo "Zip: $ZIPNAME_KSU"
else
echo "Zip: $ZIPNAME"
fi
