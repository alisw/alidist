package: defaults-o2-daq
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
disable:
  - AliEn-Runtime
  - AliRoot
  - simulation
  - generators
  - GEANT4
  - GEANT3
  - GEANT4_VMC
  - pythia
  - pythia6
  - DDS
overrides:
  ROOT:
    version: "%(tag_basename)s"
    tag: "v6-06-04"
  protobuf:
    version: "%(tag_basename)s"
    tag: "v3.0.2"
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
