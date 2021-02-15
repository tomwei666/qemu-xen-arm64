#!/bin/bash
WRKDIR=$(pwd)
BUILD=${WRKDIR}/build
BUILD_TMP=${BUILD}/out
UBOOT_BIN=${BUILD_TMP}/u-boot.bin
XEN_BIN=${BUILD_TMP}/xen
KERNEL_IMAGE=${BUILD_TMP}/Image
KERNEL1_IMAGE=/home/tom/work/BiscuitOS-ALL/BiscuitOS/output/linux-4.14.1-aarch/linux/out/arch/arm64/boot/Image
KERNEL_GZ=${BUILD_TMP}/Image.gz
ROOTFS_GZ=${BUILD_TMP}/rootfs.img.gz
#printf "0x%x\n" $(stat -c %s Image.gz)

QEMU=/home/tom/work/BiscuitOS-ALL/BiscuitOS/output/linux-5.0-aarch/qemu-system/qemu-3.1.0/aarch64-softmmu/qemu-system-aarch64


${QEMU}  -machine virt,gic_version=3 -machine virtualization=true -cpu cortex-a57 -machine type=virt -m 4096 -smp 4 -bios ${UBOOT_BIN} -device loader,file=${XEN_BIN},force-raw=on,addr=0x49000000 -device loader,file=${KERNEL_IMAGE},addr=0x47000000 -device loader,file=${KERNEL_IMAGE},addr=0x53000000 -device loader,file=virt-gicv3.dtb,addr=0x44000000 -device loader,file=${ROOTFS_GZ},addr=0x42000000  -device loader,file=${ROOTFS_GZ},addr=0x58000000 -nographic -no-reboot -chardev socket,id=qemu-monitor,host=localhost,port=7777,server,nowait,telnet -mon qemu-monitor,mode=readline
