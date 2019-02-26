package: defaults-user-ml
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  BUILD_NUMPY: 0 
  MATPLOTLIB_VERSION: "v3.0.2" 
disable:
  - DPMJET
  - GEANT3
  - GEANT4
  - GEANT4_VMC
  - arrow
overrides:
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-43
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-43-01
  Python-modules:
    requires:
      - Python3
      - FreeType
      - libpng
  Python3: 
    tag: 3.6 
  Python-modules-ml:
    requires:
      - Python3
      - Python-modules 
      - ROOT
---
