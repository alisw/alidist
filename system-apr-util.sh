package: system-apr-util
version: "1.0"
system_requirement_missing: |
  apr and its development package are missing from your system.
   * RHEL-compatible systems: you will probably need "apr-util" and "apr-util-devel" packages.
   * Ubuntu-compatible systems: you will probably need "libaprutil1" and "libaprutil1-dev".
system_requirement: ".*"
system_requirement_check: |
  apu-1-config --version > /dev/null; if test $? = 127; then exit 1; else printf "#include <apr-1/apu.h>\nint main() {}\n" | cc -xc -laprutil-1 - -o /dev/null || exit 2; fi; exit 0
---
