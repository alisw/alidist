package: defaults-generators
version: v1
disable:
  - arrow
env:
  CFLAGS: -fPIC -g -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -g -O2 -std=c++17
overrides:
  GCC-Toolchain:
    version: v12.2.0-alice1
    tag: v12.2.0-alice1
  boost:
    requires:
      - GCC-Toolchain:(?!osx)
  fastjet:
    version: v3.4.1_1.052-alice2
    tag: v3.4.1_1.052-alice2
---
