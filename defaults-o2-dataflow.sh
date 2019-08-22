package: defaults-o2-dataflow
version: v1
env:
  CXXFLAGS: "-fPIC -O2 -std=c++17"
  CFLAGS: "-fPIC -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "17"
disable:
  - AEGIS
  - AliEn-Runtime
  - AliRoot
  - ApMon-CPP
  - simulation
  - generators
  - GEANT4
  - GEANT3
  - GEANT4_VMC
  - pythia
  - pythia6
  - hijing
  - HepMC3
overrides:
  O2:
    version: "%(short_hash)s%(defaults_upper)s"
    tag: dev
  ROOT:
    tag: "v6-18-00" 
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
