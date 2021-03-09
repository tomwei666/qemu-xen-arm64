#!/bin/bash -eux

# SPDX-License-Identifier: MIT

# Copyright (c) 2019, DornerWorks, Ltd.
# Author: Stewart Hildebrand

CROSS_DIR=/home/tom/work/BiscuitOS-ALL/BiscuitOS/output/linux-5.0-aarch/aarch64-linux-gnu/
CROSS_TOOL=${CROSS_DIR}/aarch64-linux-gnu/bin/aarch64-linux-gnu-

WRKDIR=$(pwd)
BUILD=${WRKDIR}/build
BUILD_TMP=${BUILD}/out
DL=${WRKDIR}/dl

BUSYBOX_SOURCE_NAME="busybox-1.30.1.tar.bz2"
BUSYBOX_SOURCE_DIR=${BUILD}/busybox-1.30.1
BUSYBOX_INSTALL=${BUSYBOX_SOURCE_DIR}/_install

KERNEL_SOURCE_NAME="linux-4.20.11.tar.xz"
KERNEL_SOURCE_DIR=${BUILD}/linux-4.20.11
KERNEL_OUT=${BUILD_TMP}/kernel

UBOOT_SOURCE_NAME="u-boot-2019.01.tar.bz2"
UBOOT_SOURCE_DIR=${BUILD}/u-boot-2019.01

XEN_SOURCE_NAME="xen-4.12.0.tar.gz"
XEN_SOURCE_DIR=${BUILD}/xen-4.12.0


create_dir()
{
	mkdir -p ${BUILD}
	mkdir -p ${BUILD_TMP}
	mkdir -p ${KERNEL_OUT}
}
unzip_source()
{
	# copy
	cp ${DL}/${BUSYBOX_SOURCE_NAME} ${BUILD}
	cp ${DL}/${KERNEL_SOURCE_NAME} ${BUILD}
	#cp ${DL}/${XEN_SOURCE_NAME} ${BUILD}
	cp ${DL}/${UBOOT_SOURCE_NAME} ${BUILD}

	cd ${BUILD}

	tar -jxv -f ${BUSYBOX_SOURCE_NAME}
	tar -Jxv -f ${KERNEL_SOURCE_NAME}
	#tar -zxv -f ${XEN_SOURCE_NAME}
	tar -jxv -f ${UBOOT_SOURCE_NAME}

}
create_rootfs()
{
	cd ${BUSYBOX_SOURCE_DIR}
	make ARCH=arm CROSS_COMPILE=${CROSS_TOOL} clean
	make ARCH=arm CROSS_COMPILE=${CROSS_TOOL} defconfig

	# 把 "#CONFIG_DEBUG is not set" 替换成 "CONFIG_STATIC=y"
	LINE_NUM=`grep -n "CONFIG_STATIC" .config | awk -F':' '{print $1}'`
	STATIC_CONTENT="CONFIG_STATIC=y"
	sed -i "$[ LINE_NUM ]c $STATIC_CONTENT" .config
	make -j8 ARCH=arm64 CROSS_COMPILE=${CROSS_TOOL}
	make install  ARCH=arm64 CROSS_COMPILE=${CROSS_TOOL}

	cd ${BUSYBOX_INSTALL}
	mkdir proc sys dev etc etc/init.d
	touch etc/init.d/rcS
	echo "#! /bin/sh" > etc/init.d/rcS
	echo "mount -t proc none /proc" >> etc/init.d/rcS
	echo "mount -t sysfs none /sys" >> etc/init.d/rcS
	echo "/sbin/mdev -s" >> etc/init.d/rcS
	chmod +x etc/init.d/rcS
	find . | cpio -o --format=newc > ../rootfs.img
	cd ..
	gzip -c rootfs.img > rootfs.img.gz
	cp rootfs.img.gz ${BUILD_TMP}
}
uboot_config()
{
	cd ${UBOOT_SOURCE_DIR}
	make CROSS_COMPILE=${CROSS_TOOL} qemu_arm64_defconfig
}
uboot_compile()
{
	cd ${UBOOT_SOURCE_DIR}
	make CROSS_COMPILE=${CROSS_TOOL} -j4
	cp u-boot.bin ${BUILD_TMP}
}
kernel_config()
{
	cd ${KERNEL_SOURCE_DIR}
	make ARCH=arm64 CROSS_COMPILE=${CROSS_TOOL} O=${KERNEL_OUT} defconfig
	echo "CONFIG_XEN_DOM0=y" >> ${KERNEL_OUT}/.config
}
kernel_compile()
{
	cd ${KERNEL_SOURCE_DIR}
    make -j8 ARCH=arm64 CROSS_COMPILE=${CROSS_TOOL} O=${KERNEL_OUT}
	cp ${KERNEL_OUT}/arch/arm64/boot/Image.gz ${BUILD_TMP}
	cp ${KERNEL_OUT}/arch/arm64/boot/Image ${BUILD_TMP}
}
xen_compile()
{
	cd ${XEN_SOURCE_DIR}

	CONTENT_1="CONFIG_DEBUG"
	CONTENT_2="CONFIG_DEBUG=y"
	CONTENT_3="CONFIG_DEBUG_INFO=y"
	CONTENT_4="CONFIG_FRAME_POINTER=y"
	CONTENT_5="# CONFIG_COVERAGE is not set"
	CONTENT_6="# CONFIG_LOCK_PROFILE is not set"
	CONTENT_7="# CONFIG_PERF_COUNTERS is not set"
	CONTENT_8="CONFIG_VERBOSE_DEBUG=y"
	CONTENT_9="CONFIG_DEVICE_TREE_DEBUG=y"
	CONTENT_10="CONFIG_SCRUB_DEBUG=y"

	CONTENT_11="CONFIG_SCHED_ARINC653"
	CONTENT_12="CONFIG_SCHED_ARINC653=y"

   if cat xen/.config | grep "$CONTENT_2">/dev/null
	then
		echo "No need to make defconfig"
	else
		echo "xen make defconfig"
		make -C xen XEN_TARGET_ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CONFIG_EARLY_PRINTK=pl011,0x09000000,115200 defconfig
		echo "Add debug into .config!"
		LINE_NUM=`grep -n "${CONTENT_1}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]c $CONTENT_2" xen/.config
		LINE_NUM=`grep -n "${CONTENT_2}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_3" xen/.config
		LINE_NUM=`grep -n "${CONTENT_3}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_4" xen/.config
		LINE_NUM=`grep -n "${CONTENT_4}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_5" xen/.config
		LINE_NUM=`grep -n "${CONTENT_5}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_6" xen/.config
		LINE_NUM=`grep -n "${CONTENT_6}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_7" xen/.config
		LINE_NUM=`grep -n "${CONTENT_7}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_8" xen/.config
		LINE_NUM=`grep -n "${CONTENT_8}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_9" xen/.config
		LINE_NUM=`grep -n "${CONTENT_9}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]a $CONTENT_10" xen/.config
		LINE_NUM=`grep -n "${CONTENT_11}" xen/.config | awk -F':' '{print $1}'`
		sed -i "$[ LINE_NUM ]c ${CONTENT_12}" xen/.config
	fi
	make XEN_TARGET_ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CONFIG_EARLY_PRINTK=pl011,0x09000000,115200 dist-xen -j
	cp xen/xen ${BUILD_TMP}
}

make_all()
{
	create_dir
	unzip_source
	create_rootfs
	uboot_config
	uboot_compile
	kernel_config
	kernel_compile
	xen_compile
}	

case $1 in                                                                         
	    "all")                                                                        
			make_all                                                                 
			;; 
		"uboot")                                                                       
			uboot_compile                                                                  
			;; 
		"kernel")                                                                             
			kernel_compile                                                                  
			;;                                                                         
	    "xen")                                                                        
			xen_compile
			;; 
	    "rootfs")                                                                        
			create_rootfs
			;; 
	    "help")                                                                        
			echo "all-----compile project"                                                                 
			echo "uboot-----compile uboot"                                                                 
			echo "kernel-----compile kernel"                                                                 
			echo "xen-----compile xen"                                                                 
			echo "rootfs-----create rootfs"                                                                 
			;; 
esac  
