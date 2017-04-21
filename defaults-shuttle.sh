package: defaults-shuttle
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++98"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  ALICE_SHUTTLE: "1"
  SHUTTLE_DIM: $HOME/dim
disable:
  - fastjet
  - DPMJET
  - GEANT3
  - GEANT4
  - GEANT4_VMC
---
