#!/bin/bash
WRKDIR=$(pwd)
BUILD=${WRKDIR}/build
BUILD_TMP=${BUILD}/out
ROOTFS_GZ=${BUILD_TMP}/rootfs.img.gz
KERNEL_GZ=${BUILD_TMP}/Image.gz
FILE=domain0.txt

SIZE_KERNEL=`printf "0x%x\n" $(stat -c %s ${KERNEL_GZ})`
SIZE_ROOTFS=`printf "0x%x\n" $(stat -c %s ${ROOTFS_GZ})`

echo "fdt addr 0x44000000" > ${FILE} 
echo "fdt resize" >> ${FILE}
echo "fdt set /chosen \#address-cells <1>" >> ${FILE}
echo "fdt set /chosen \#size-cells <1>" >> ${FILE}
echo "fdt mknod /chosen module@0" >>${FILE}
echo "fdt set /chosen/module@0 compatible \"xen,linux-zimage\" \"xen,multiboot-module\"" >>${FILE}
echo "fdt set /chosen/module@0 reg <0x47000000 ${SIZE_KERNEL}>" >>${FILE}
echo "fdt set /chosen/module@0 bootargs \"rw root=/dev/ram rdinit=/sbin/init   earlyprintk=serial,ttyAMA0 console=hvc0 earlycon=xenboot\"" >>${FILE}
echo "fdt mknod /chosen module@1" >>${FILE}
echo "fdt set /chosen/module@1 compatible \"xen,linux-initrd\" \"xen,multiboot-module\"" >>${FILE}
echo "fdt set /chosen/module@1 reg <0x42000000 ${SIZE_ROOTFS}>" >>${FILE}
echo "booti 0x49000000 - 0x44000000" >>${FILE}
