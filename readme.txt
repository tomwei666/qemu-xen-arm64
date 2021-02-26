1. 需要如下源码:
--ftp://ftp.denx.de/pub/u-boot/u-boot-2019.01.tar.bz2
--https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.20.11.tar.xz
--wget -c https://downloads.xenproject.org/release/xen/4.12.0/xen-4.12.0.tar.gz
--https://busybox.net/downloads/busybox-1.30.1.tar.bz2
--qemu-3.1.0.tar.xz
---apt install gcc-aarch64-linux-gnu
我的环境之前搭建BiscuitOS,已经有gcc-aarch64-linux-gnu和qemu，编译脚本不再有这个。

添加gcc-aarch64-linux-gnu已有的目录:
CROSS_TOOL=${CROSS_DIR}/aarch64-linux-gnu/bin/aarch64-linux-gnu- 

2. 下载源码，在工程根目录，新建dl，放入源码压缩包如下:
tom@ubuntu:~/work/BiscuitOS-ALL/BiscuitOS/output/xen-arm64/dl$ ls -al
total 148840
drwxr-xr-x 2 tom tom      4096 Feb 12 11:40 .
drwxr-xr-x 4 tom tom      4096 Feb 15 20:20 ..
-rwxr--r-- 1 tom tom   7793781 Feb 12 11:04 busybox-1.30.1.tar.bz2
-rwxrw-rw- 1 tom tom 104286296 Feb 12 11:09 linux-4.20.11.tar.xz
-rw-r--r-- 1 tom tom  13366005 Feb 12 11:40 u-boot-2019.01.tar.bz2
-rwxr--r-- 1 tom tom  26949697 Feb 12 11:04 xen-4.12.0.tar.gz

3. 编译
  整体编译: ./qemuxen.sh all
  u-boot:   ./qemuxen.sh uboot
  kernel:   ./qemuxen.sh kernel
  xen:      ./qemuxen.sh xen
  rootfs:  ./qemuxen.sh rootfs

4. 产生配置文件
 ./gen-xen-domain0.sh会产生domain0.txt
 ./gen-xen-domainN.sh会产生domainN.txt

5. 启动脚本：
  domain0.sh:会启动一个domain0
  domainN.sh:会启动一个domain0和domain1


6. 想启动一个domain0的步骤:

./qemuxen.sh all
./gen-xen-domain0.sh生成domain0.txt
./domain0.sh
然后输入配置文件domain0.txt内容。

启动成功后的串口日志:
[    2.098942] i2c /dev entries driver
[    2.129100] sdhci: Secure Digital Host Controller Interface driver
[    2.130056] sdhci: Copyright(c) Pierre Ossman
[    2.133188] Synopsys Designware Multimedia Card Interface Driver
[    2.141750] sdhci-pltfm: SDHCI platform and OF driver helper
[    2.152238] ledtrig-cpu: registered to indicate activity on CPUs
[    2.160965] usbcore: registered new interface driver usbhid
[    2.161819] usbhid: USB HID core driver
[    2.184313] NET: Registered protocol family 17
[    2.186677] 9pnet: Installing 9P2000 support
[    2.187860] Key type dns_resolver registered
[    2.196274] registered taskstats version 1
[    2.196911] Loading compiled-in X.509 certificates
[    2.210805] input: gpio-keys as /devices/platform/gpio-keys/input/input0
[    2.216513] rtc-pl031 9010000.pl031: setting system clock to 2021-02-15 12:30:17 UTC (1613392217)
[    2.219020] ALSA device list:
[    2.219444]   No soundcards found.
[    2.629814] Freeing unused kernel memory: 1344K
[    2.633502] Run /sbin/init as init process
Please press Enter to activate this console.
/ # uname -a
Linux (none) 4.20.11 #1 SMP PREEMPT Sat Feb 13 20:58:55 CST 2021 aarch64 GNU/Linux
/ # (XEN) *** Serial input to Xen (type 'CTRL-a' three times to switch input)
(XEN) *** Serial input to DOM0 (type 'CTRL-a' three times to switch input)


7. 想启动一个domain0和domain1的步骤:
./qemuxen.sh all
./gen-xen-domainN.sh生成domain0.txt
./domainN.sh
然后输入配置文件domainN.txt内容。

成功的启动日志:

(XEN) DOM1: [    3.315451] ohci-platform: OHCI generic platform driver
[    3.322437] Freeing unused kernel memory: 1344K
(XEN) DOM1: [    3.317324] ohci-exynos: OHCI EXYNOS driver
[    3.329758] Run /sbin/init as init process
(XEN) DOM1: [    3.332064] usbcore: registered new interface driver usb-storage
(XEN) DOM1: [    3.378084] i2c /dev entries driver
(XEN) DOM1: [    3.453906] sdhci: Secure Digital Host Controller Interface driver
(XEN) DOM1: [    3.455682] sdhci: Copyright(c) Pierre Ossman
(XEN) DOM1: [    3.463319] Synopsys Designware Multimedia Card Interface Driver
(XEN) DOM1: [    3.480748] sdhci-pltfm: SDHCI platform and OF driver helper
(XEN) DOM1: [    3.494835] ledtrig-cpu: registered to indicate activity on CPUs
(XEN) DOM1: [    3.520041] usbcore: registered new interface driver usbhid
(XEN) DOM1: [    3.522993] usbhid: USB HID core driver
(XEN) DOM1: [    3.559546] NET: Registered protocol family 17
(XEN) DOM1: [    3.564096] 9pnet: Installing 9P2000 support
(XEN) DOM1: [    3.567257] Key type dns_resolver registered
(XEN) DOM1: [    3.574169] registered taskstats version 1
(XEN) DOM1: [    3.575670] Loading compiled-in X.509 certificates
(XEN) DOM1: [    3.584495] hctosys: unable to open rtc device (rtc0)
(XEN) DOM1: [    3.588727] ALSA device list:
(XEN) DOM1: [    3.590528]   No soundcards found.
(XEN) DOM1: [    4.006617] Freeing unused kernel memory: 1344K
(XEN) DOM1: [    4.015000] Run /sbin/init as init process

Please press Enter to activate this console. (XEN) DOM1:

/ # (XEN) *** Serial input to DOM1 (type 'CTRL-a' three times to switch input)
(XEN) Please press Enter to activate this console.
(XEN)
/ # uname -a
(XEN) Linux (none) 4.20.11 #1 SMP PREEMPT Sat Feb 13 20:58:55 CST 2021 aarch64 GNU/Linux
(XEN) / # *** Serial input to Xen (type 'CTRL-a' three times to switch input)
(XEN) *** Serial input to DOM0 (type 'CTRL-a' three times to switch input)

/ # uname -a
Linux (none) 4.20.11 #1 SMP PREEMPT Sat Feb 13 20:58:55 CST 2021 aarch64 GNU/Linux


  
参考:
https://medium.com/@denisobrezkov/xen-on-arm-and-qemu-1654f24dea75


