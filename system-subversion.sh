package: system-subversion
version: "1.0"
system_requirement_missing: |
  apr and its development package are missing from your system.
   * RHEL-compatible systems: you will probably need the "subversion" package.
   * Ubuntu-compatible systems: you will probably need "subversion".
system_requirement: ".*"
system_requirement_check: |
  svn --version > /dev/null; if test $? = 127; then exit 1; fi; exit 0
---
