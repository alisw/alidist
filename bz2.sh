package: bz2
version: 1.0
system_requirement_missing: "Please install bzip2 development package on your system"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <bzlib.h>\n" | gcc -xc++ - -c -o /dev/null
---

