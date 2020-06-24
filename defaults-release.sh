package: defaults-release
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
override:
  # Pinpoint AliRoot/AliPhysics
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-20l
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-20l-01
---

# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
