package: system-apr
version: "1.0"
system_requirement_missing: |
  apr and its development package are missing from your system.
   * RHEL-compatible systems: you will probably need "apr" and "apr-devel" packages.
   * Ubuntu-compatible systems: you will probably need "libapr1" and "libapr1-dev".
system_requirement: ".*"
system_requirement_check: |
  apr-1-config --version > /dev/null; if test $? = 127; then exit 1; else printf "#include <apr-1/apr.h>\nint main() {}\n" | cc -xc -lapr-1 - -o /dev/null || exit 2; fi; exit 0
---
