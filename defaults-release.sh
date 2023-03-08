package: defaults-release
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  # Pinpoint AliRoot/AliPhysics
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-38m
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-38m-01
  # Use VMC packages compatible with ROOT 5
  GEANT3:
    version: "v2-7-p2"
    tag: "v2-7-p2"
  GEANT4_VMC:
    version: "v3-6-p6-inclxx-biasing-p5"
    tag: "v3-6-p6-inclxx-biasing-p5"
  GEANT4:
    source: https://github.com/alisw/geant4.git
    version: "v10.4.2-alice3"
    tag: "v10.4.2-alice3"
  vgm:
    version: "v4-4"
    tag: "v4-4"
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
