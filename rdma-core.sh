package: rdma-core
version: "1.0"
system_requirement_missing: |
  Please install rdma-core on your system
     * On RHEL-compatible systems you probably need: rdma-core-devel
system_requirement: ".*"
system_requirement_check: |
  printf "#include <rdma/rdma_cma.h>" | cc -xc - -c -o /dev/null
---
