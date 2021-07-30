env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++17
  CXXSTD: '17'
  ENABLE_VMC: 'ON'
  GEANT4_BUILD_MULTITHREADED: 'ON'
overrides:
  AliPhysics:
    version: '%(commit_hash)s_O2'
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
    version: '%(commit_hash)s_O2'
  GCC-Toolchain:
    tag: v10.2.0-alice2
    version: v10.2.0-alice2
  O2:
    tag: nightly-20210728
    version: '%(tag_basename)s'
  O2Physics:
    tag: nightly-20210727
    version: '%(tag_basename)s'
  XRootD:
    source: https://github.com/xrootd/xrootd
    tag: v4.12.8
  cgal:
    version: 4.12.2
  fastjet:
    tag: v3.3.3_1.042-alice1
  pythia:
    requires:
    - lhapdf
    - boost
    tag: v8304
package: defaults-o2
version: v1

---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
