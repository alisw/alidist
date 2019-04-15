package: defaults-jalien
version: v1
disable:
  - arrow
  - treelite
overrides:
  XRootD:
    version: "%(tag_basename)s_JALIEN"
    tag: "v4.8.5"
    source: https://github.com/xrootd/xrootd
    build_requires:
      - CMake
    requires:
      - "GCC-Toolchain:(?!osx)"
      - "OpenSSL:(?!osx)"
      - "osx-system-openssl:(osx.*)"
      - ApMon-CPP
      - libxml2
  JDK:
    version: "10.0.2_JALIEN"
  libxml2:
    version: "%(tag_basename)s_JALIEN"
    overrides:
    requires:
      - zlib
    build_requires:
      - autotools
      - "GCC-Toolchain:(?!osx)"
  OpenSSL:
    version: "v1.0.2o_JALIEN"
    overrides:
    requires:
      - zlib
    build_requires:
      - "GCC-Toolchain:(?!osx)"
  ApMon-CPP:
    version: "%(tag_basename)s"
    requires:
      - "GCC-Toolchain:(?!osx)"
    build_requires:
      - autotools
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-48-01
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-48
    requires:
      - JAliEn-ROOT
      - ROOT
      - fastjet:(?!.*ppc64)
      - Vc
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

