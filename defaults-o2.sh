package: defaults-o2
version: v1
env:
  CXXFLAGS: "-fPIC -O2 -std=c++17"
  CFLAGS: "-fPIC -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "17"
  GEANT4_BUILD_MULTITHREADED: "ON"
disable:
  - AliEn-Runtime
  - JAliEn-ROOT
  - AliEn-ROOT-Legacy
  - ApMon-CPP
overrides:
  AliRoot:
    version: "%(commit_hash)s_O2"
    requires:
      - ROOT
      - fastjet:(?!.*ppc64)
      - GEANT3
      - GEANT4_VMC
      - Vc
      - ZeroMQ
  pythia:
    requires:
      - lhapdf
      - boost
  AliPhysics:
    version: "%(commit_hash)s_O2"
  ROOT:
    tag: "v6-18-02" 
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
