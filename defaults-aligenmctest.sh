package: defaults-aligenmctest
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  AliDPG:
    source: https://github.com/alipwgmm/AliDPG
    tag: alidpg_aligenmc
  aligenmc:
    source: https://github.com/alipwgmm/aligenmc
    tag: alidpg_aligenmc
---
# Test environment for special AliDPG and aligenmc deployment for PWGMM.
