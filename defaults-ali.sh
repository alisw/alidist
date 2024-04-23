disable:
- mesos
- MySQL
env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
  ENABLE_VMC: 'ON'
  GEANT4_BUILD_MULTITHREADED: 'OFF'
  MACOSX_DEPLOYMENT_TARGET: '10.15'
overrides:
  AliPhysics:
    tag: vAN-20240423
    version: '%(tag_basename)s_O2'
  AliRoot:
    requires:
    - ROOT
    - DPMJET
    - fastjet:(?!.*ppc64)
    - GEANT3
    - GEANT4_VMC
    - Vc
    - ZeroMQ
    - JAliEn-ROOT
    tag: v5-09-59z
    version: '%(commit_hash)s_O2'
  GCC-Toolchain:
    tag: v12.2.0-alice1
    version: v12.2.0-alice1
  ROOT:
    tag: v6-30-05-alice1
  cgal:
    version: 4.12.2
  fastjet:
    tag: v3.4.1_1.052-alice2
  pythia:
    requires:
    - lhapdf
    - boost
    tag: v8304-alice1
package: defaults-ali
version: v1

---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
