#!/bin/bash
WRKDIR=$(pwd)
BUILD=${WRKDIR}/build
BUILD_TMP=${BUILD}/out
ROOTFS_GZ=${BUILD_TMP}/rootfs.img.gz
KERNEL_IMG=${BUILD_TMP}/Image
FILE_ORIGIN=domainN-origin.txt
FILE=domainN.txt

SIZE_KERNEL1=`printf "0x%x\n" $(stat -c %s ${KERNEL_IMG})`
SIZE_ROOTFS1=`printf "0x%x\n" $(stat -c %s ${ROOTFS_GZ})`
SIZE_KERNEL2=`printf "0x%x\n" $(stat -c %s ${KERNEL_IMG})`
SIZE_ROOTFS2=`printf "0x%x\n" $(stat -c %s ${ROOTFS_GZ})`
CONTENT_KERNEL1="fdt set /chosen/module@0 reg <0x47000000 ${SIZE_KERNEL1}>"
STATIC_CONTENT="CONFIG_STATIC=y"
CONTENT_KERNEL2="fdt set /chosen/domU1/module@0 reg <0x53000000 ${SIZE_KERNEL2}>"
CONTENT_ROOTFS1="fdt set /chosen/module@1 reg <0x42000000 ${SIZE_ROOTFS1}>"
CONTENT_ROOTFS2="fdt set /chosen/domU1/module@1 reg <0x58000000 ${SIZE_ROOTFS2}>"
GREP_KERNEL1="IMAGE1_SIZE"
GREP_KERNEL2="IMAGE2_SIZE"
GREP_ROOTFS1="ROOTFS1_SIZE"
GREP_ROOTFS2="ROOTFS2_SIZE"

IMAGE1_CONTENT="IMAGE1_SIZE"
IMAGE2_CONTENT="IMAGE2_SIZE"
ROOTFS1_CONTENT="ROOTFS1_SIZE"
ROOTFS2_CONTENT="ROOTFS2_SIZE"

cp ${FILE_ORIGIN} ${FILE}

LINE_NUM=`grep -n ${GREP_KERNEL1} ${FILE} | awk -F':' '{print $1}'`
echo $LINE_NUM
sed -i "$[ LINE_NUM ]c ${CONTENT_KERNEL1}" ${FILE} 

LINE_NUM=`grep -n ${GREP_KERNEL2} ${FILE} | awk -F':' '{print $1}'`
sed -i "$[ LINE_NUM ]c ${CONTENT_KERNEL2}" ${FILE} 

LINE_NUM=`grep -n ${GREP_ROOTFS1} ${FILE} | awk -F':' '{print $1}'`
sed -i "$[ LINE_NUM ]c ${CONTENT_ROOTFS1}" ${FILE} 

LINE_NUM=`grep -n ${GREP_ROOTFS2} ${FILE} | awk -F':' '{print $1}'`
sed -i "$[ LINE_NUM ]c ${CONTENT_ROOTFS2}" ${FILE} 
