package: snappy
version: "%(tag_basename)s"
tag: 1.1.3
source: https://github.com/google/snappy
build_requires:
  - "GCC-Toolchain:(?!osx)"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <snappy.h>\n" | c++ -xc++ -I$(brew --prefix snappy)/include - -c -M 2>&1
---
