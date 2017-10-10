package: defaults-pwgmmtest
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  aligenmc:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/aligenmc
  ampt:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/ampt
  herwig:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/herwig
  lhapdf:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/lhapdf
  powheg:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/powheg
  pythia6:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/pythia6
  pythia:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/pythia8
  sacrifice:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/sacrifice
  thepeg:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/thepeg
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
