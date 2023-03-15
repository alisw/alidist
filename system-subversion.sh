package: system-subversion
version: "1.0"
build_requires:
  - system-apr
system_requirement_missing: |
  apr and its development package are missing from your system.
   * RHEL-compatible systems: you will probably need the "subversion" and "subversion-devel" packages.
   * Ubuntu-compatible systems: you will probably need "subversion" and "subversion-dev".
system_requirement: ".*"
system_requirement_check: |
  svn --version > /dev/null; if test $? = 127; then exit 1; else printf "#include <subversion-1/svn_version.h>\nint main() {}\n" | cc -xc -I/usr/include/apr-1 -lapr-1 - -o /dev/null || exit 2; fi; exit 0
---
