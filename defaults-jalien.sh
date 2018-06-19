package: defaults-jalien
version: v1
overrides:
  xrootd:
    tag: "v4.8.3"
    source: https://github.com/xrootd/xrootd
    build_requires:
      - CMake
      - "GCC-Toolchain:(?!osx)"
    requires:
      - "OpenSSL:(?!osx)"
      - "osx-system-openssl:(osx.*)"
      - ApMon-CPP
      - libxml2
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

