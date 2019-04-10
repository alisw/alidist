package: ofi
version: "1.6.0"
system_requirement_missing: |
  libfabric and its development package are missing from your system.
   * RHEL-compatible systems: you will probably need "libfabric" and "libfabric-devel" packages.
   * Ubuntu-compatible systems: you will probably need "libfabric-bin" and "libfabric-dev".
system_requirement: ".*"
system_requirement_check: |
  pkg-config --atleast-version=1.6.0 libfabric 2>&1 && printf "#include \"rdma/fabric.h\"\nint main(){}" | gcc -xc - -o /dev/null
---
