package: defaults-generators
version: v1
disable:
  - arrow
env:
  CFLAGS: -fPIC -g -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -g -O2 -std=c++14
overrides:
  GCC-Toolchain:
    version: v10.2.0-alice2
    tag: v10.2.0-alice2
  boost:
    requires:
      - GCC-Toolchain:(?!osx)
  fastjet:
    version: v3.4.0_1.045-alice1
    tag: v3.4.0_1.045-alice1
  pythia:
    tag: v8304
    requires:
      - lhapdf
      - boost
---
