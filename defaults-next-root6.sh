package: defaults-next-root6
version: v1
disable:
  - arrow
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "11"
  ENABLE_VMC: "ON"
overrides:
  AliRoot:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-57d
  AliPhysics:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-57d-01
---
