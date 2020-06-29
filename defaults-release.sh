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
    tag: v5-09-24e
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-24e-01
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
