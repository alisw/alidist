disable:
- arrow
env:
  CFLAGS: -fPIC -g -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -g -O2 -std=c++11
  CXXSTD: '11'
  ENABLE_VMC: 'ON'
overrides:
  AliPhysics:
    tag: TEST-IGNORE-nightly-20210831-next-root6
    version: '%(tag_basename)s'
  AliRoot:
    tag: TEST-IGNORE-nightly-20210831-next-root6
    version: '%(tag_basename)s'
package: defaults-next-root6
version: v1

---
