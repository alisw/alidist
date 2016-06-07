package: lz4
version: "%(tag_basename)s"
source: https://github.com/Cyan4973/lz4
tag: r131
build_requires:
 - "GCC-Toolchain:(?!osx)"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <lz4.h>\n" | gcc -xc++ -I$(brew --prefix lz4)/include - -c -M 2>&1
---
