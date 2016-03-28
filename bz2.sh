package: bz2
version: "%(tag_basename)s"
source: https://github.com/star-externals/zlib
tag: v1.2.8
build_requires:
 - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <bzlib.h>\n" | gcc -xc++ - -c -o /dev/null
---
#!/bin/sh

echo "Please install bzip2 development package on your system"
exit 1
