package: system-openssl
version: "1.0"
system_requirement_missing: |
  Please make sure you install openssl:
   * RHEL-compatible systems: you will probably need "openssl" and "openssl-devel" packages.
system_requirement: "slc8.*"
system_requirement_check: |
  echo '#include <openssl/bio.h>' | c++ -x c++ - -c -o /dev/null
---

