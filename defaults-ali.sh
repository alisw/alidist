package: defaults-ali
version: v1
env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
  ENABLE_VMC: 'ON'
  GEANT4_BUILD_MULTITHREADED: 'OFF'
disable:
  - mesos
  - MySQL
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
  vgm:
    tag: "v5-2"
  cgal:
    version: 4.12.2
  fastjet:
    tag: v3.4.1_1.052-alice2
  ROOT:
    tag: v6-30-05-alice1
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
