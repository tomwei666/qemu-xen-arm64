#!/bin/bash
QEMU=/home/tom/work/BiscuitOS-ALL/BiscuitOS/output/linux-5.0-aarch/qemu-system/qemu-3.1.0/aarch64-softmmu/qemu-system-aarch64
${QEMU} -machine virt,gic_version=3 -machine virtualization=true -cpu cortex-a57 -machine type=virt -m 4096 -smp 4 -display none -machine dumpdtb=virt-gicv3.dtb 
