package: defaults-staging_pwgmm
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  aligenmc:
    source: https://github.com/alipwgmm/aligenmc
  ampt:
    source: https://github.com/alipwgmm/ampt
  herwig:
    source: https://github.com/alipwgmm/herwig
  powheg:
    source: https://github.com/alipwgmm/powheg
  pythia6:
    source: https://github.com/alipwgmm/pythia6
  pythia:
    source: https://github.com/alipwgmm/pythia8
  sacrifice:
    source: https://github.com/alipwgmm/sacrifice
  thepeg:
    source: https://github.com/alipwgmm/thepeg
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
