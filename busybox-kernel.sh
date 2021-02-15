#!/bin/bash
QEMU=/home/tom/work/BiscuitOS-ALL/BiscuitOS/output/linux-5.0-aarch/qemu-system/qemu-3.1.0/aarch64-softmmu/qemu-system-aarch64
WRKDIR=$(pwd)
BUILD=${WRKDIR}/build
BUILD_TMP=${BUILD}/out

KERNEL_GZ=${BUILD_TMP}/Image.gz
ROOTFS_GZ=${BUILD_TMP}/rootfs.img.gz
${QEMU} -machine virt,gic_version=3 -machine virtualization=true -cpu cortex-a57 -machine type=virt -m 4096 -smp 4 -kernel ${KERNEL_GZ} -nographic -no-reboot -initrd ${ROOTFS_GZ} -append "rw root=/dev/ram rdinit=/sbin/init  earlyprintk=serial,ttyAMA0 console=ttyAMA0"
