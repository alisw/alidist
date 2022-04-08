package: defaults-next-root6
version: v1
disable:
  - arrow
env:
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
overrides:
  AliRoot:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-59b
  AliPhysics:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-59b-01
---
