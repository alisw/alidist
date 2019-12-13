package: defaults-jalien
version: v1
disable:
  - arrow
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  XRootD:
    version: "%(tag_basename)s_JALIEN"
    tag: "v4.10.0"
    source: https://github.com/xrootd/xrootd
  JDK:
    version: "12.0.1_JALIEN"
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
    version: "%(tag_basename)s_JALIEN"
    tag: v5-09-52-01
  AliRoot:
    version: "%(tag_basename)s_JALIEN"
    tag: v5-09-52
    requires:
      - ROOT
      - DPMJET
      - fastjet:(?!.*ppc64)
      - GEANT3
      - GEANT4_VMC
      - Vc
      - JAliEn-ROOT
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

