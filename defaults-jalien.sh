package: defaults-jalien
version: v1
overrides:
  xrootd:
    version: "%(tag_basename)s_JALIEN"
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
  JDK:
    version: "10.0.1_JALIEN"
  libxml2:
    version: "%(tag_basename)s_JALIEN"
  OpenSSL:
    version: "v1.0.2o_JALIEN"
  ApMon-CPP:
    version: "%(tag_basename)s"
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

