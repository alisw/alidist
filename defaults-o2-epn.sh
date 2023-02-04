package: defaults-o2-epn
version: v1
env:
  CFLAGS: -fPIC -O3 -march=znver2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O3 -march=znver2 -std=c++17
  O2_CXXFLAGS_OVERRIDE: -O3
  CXXSTD: '17'
  ENABLE_VMC: 'ON'
  GEANT4_BUILD_MULTITHREADED: 'ON'
disable:
  - O2Physics
  - OpenSSL
  - curl
  - mesos
overrides:
  AliPhysics:
    version: '%(commit_hash)s_O2'
  AliRoot:
    version: '%(commit_hash)s_O2'
    requires:
      - ROOT
      - DPMJET
      - fastjet:(?!.*ppc64)
      - GEANT3
      - GEANT4_VMC
      - Vc
      - ZeroMQ
      - JAliEn-ROOT
  GCC-Toolchain:
    tag: v12.2.0-alice1
    version: v12.2.0-alice1
  cgal:
    version: 4.12.2
  fastjet:
    tag: v3.4.0_1.045-alice1
  pythia:
    tag: v8304
    requires:
      - lhapdf
      - boost
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
