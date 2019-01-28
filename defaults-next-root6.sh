package: defaults-next-root6
version: v1
disable:
  - arrow
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  EXTERNAL_ALIEN: 1
overrides:
  AliRoot:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-46
  AliPhysics:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-46-01
---
