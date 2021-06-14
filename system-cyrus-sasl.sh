package: system-cyrus-sasl
version: "1.0"
system_requirement_missing: |
  apr and its development package are missing from your system.
   * RHEL-compatible systems: you will probably need "cyrus-sasl" and "cyrus-sasl-devel" packages, as well as possibly "cyrus-sasl-md5".
   * Ubuntu-compatible systems: you will probably need "libsasl2" and "libsasl2-dev".
system_requirement: ".*"
system_requirement_check: |
  saslauthd -v > /dev/null; if test $? = 127; then exit 1; else printf "#include <sasl/md5global.h>\nint main() {}\n" | cc -xc -lsasl2 - -o /dev/null || exit 2; fi; exit 0
---
