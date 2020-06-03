package: defaults-user-next-root6
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
disable:
  - DPMJET
  - GEANT3
  - GEANT4
  - GEANT4_VMC
  - arrow
overrides:
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-54a
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-54a-01
---
