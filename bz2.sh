package: bz2
version: 1.0
system_requirement_missing: |
  Please install bzip2 development package on your system:
    * On RHEL-compatible systems: bzip2-devel
    * On Ubuntu-compatible systems: libbz2-dev
system_requirement: ".*"
system_requirement_check: |
  printf "#include <bzlib.h>\n" | gcc -xc++ - -c -o /dev/null
---

