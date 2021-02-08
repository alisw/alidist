package: defaults-jalien
version: v1
disable:
  - arrow
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  AliRoot:
    version: "%(tag_basename)s_JALIEN"
    tag: v5-09-56
  AliPhysics:
    version: "%(tag_basename)s_JALIEN"
    tag: v5-09-56-01
  fastjet:
    tag: v3.3.4_1.045-alice1
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

