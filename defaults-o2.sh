package: defaults-o2
version: v1
env:
  CXXFLAGS: "-fPIC -O2 -std=c++17"
  CFLAGS: "-fPIC -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "17"
  GEANT4_BUILD_MULTITHREADED: "ON"
  ENABLE_VMC: "ON"
overrides:
  AliRoot:
    version: "%(commit_hash)s_O2"
    tag: v5-09-56v
    requires:
      - ROOT
      - DPMJET
      - fastjet:(?!.*ppc64)
      - GEANT3
      - GEANT4_VMC
      - Vc
      - ZeroMQ
      - JAliEn-ROOT
  pythia:
    tag: "v8302"
    requires:
      - lhapdf
      - boost
  AliPhysics:
    version: "%(commit_hash)s_O2"
    tag: v5-09-56v-01
  cgal:
    version: "4.12.2"
  fastjet:
    tag: "v3.3.3_1.042-alice1"
  XRootD:
    tag: "v4.11.1"
    source: https://github.com/xrootd/xrootd
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
