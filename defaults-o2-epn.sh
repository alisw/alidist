package: defaults-o2-epn
version: v1
env:
  CFLAGS: -fPIC -O3 -march=znver2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O3 -march=znver2 -std=c++20
  O2_CXXFLAGS_OVERRIDE: -O3
  CXXSTD: '20'
  ENABLE_VMC: 'ON'
  GEANT4_BUILD_MULTITHREADED: 'OFF'
disable:
  - AliGenerators
  - AliGenO2
  - O2Physics
  - KFParticle
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
  cgal:
    version: 4.12.2
  fastjet:
    tag: v3.4.0_1.045-alice1
  DataDistribution:
    requires:
      - "GCC-Toolchain:(?!osx)"
      - boost
      - FairLogger
      - libInfoLogger
      - FairMQ
      - Ppconsul
      - grpc
      - Monitoring
      - protobuf
      - O2
      - fmt
      - ucx   # this one added
  FairMQ:
    tag: "v1.9.2"
  ROOT:
    tag: "v6-32-06-alice10"
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
