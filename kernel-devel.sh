package: kernel-devel
version: "1.0"

system_requirement_missing: |
  Kernel development packages are missing on your system:
  * RHEL-compatible systems: Please install kernel-devel, pciutils-devel and kmod-devel
  * Ubuntu-compatible systems: Please install linux-headers-`uname -r` , libpci-dev, and libkmod-dev
system_requirement: ".*"
system_requirement_check: "find /usr/src -name kernel.h | grep include/linux/kernel.h  > /dev/null 2>&1 && ls /usr/include/libkmod.h  > /dev/null 2>&1 && find /usr/include -name pci.h | grep pci/pci.h  > /dev/null 2>&1"
---
