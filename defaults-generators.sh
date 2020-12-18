disable:
- arrow
env:
  CFLAGS: -fPIC -g -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -g -O2 -std=c++14
overrides:
  AliGenerators:
    tag: rc/vAN-20201218
  boost:
    requires:
    - GCC-Toolchain:(?!osx)
  fastjet:
    tag: v3.3.3_1.042-alice1
    version: v3.3.3_1.042-alice1
package: defaults-dev
version: v1

---
