package: kernel-devel
version: "1.0"

system_requirement_missing: "Please install kernel-devel pciutils-devel kmod-devel"
system_requirement: ".*"
system_requirement_check: "ls /usr/src/kernels/*/include/linux/kernel.h > /dev/null 2>&1 && ls /usr/include/libkmod.h  > /dev/null 2>&1 && ls /usr/include/pci/pci.h > /dev/null 2>&1"

---
