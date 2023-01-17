package: defaults-next-root6
version: v1
disable:
  - arrow
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++17"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: '17'
overrides:
  AliRoot:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-59k
  AliPhysics:
    version: "%(tag_basename)s_ROOT6"
    tag: v5-09-59k-01
---
