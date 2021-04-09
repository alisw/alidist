disable:
- arrow
env:
  CFLAGS: -fPIC -g -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -g -O2 -std=c++11
overrides:
  AliPhysics:
    tag: vAN-20210409
    version: '%(tag_basename)s_JALIEN'
  AliRoot:
    tag: v5-09-56
    version: '%(tag_basename)s_JALIEN'
  fastjet:
    tag: v3.3.4_1.045-alice1
package: defaults-jalien
version: v1

---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

