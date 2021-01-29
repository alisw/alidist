disable:
- arrow
env:
  CFLAGS: -fPIC -g -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -g -O2 -std=c++11
overrides:
  AliPhysics:
    tag: vAN-20210129
    version: '%(tag_basename)s_ROOT6'
  AliRoot:
    tag: v5-09-57
    version: '%(tag_basename)s_ROOT6'
package: defaults-next-root6
version: v1

---
