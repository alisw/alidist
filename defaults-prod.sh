package: defaults-prod
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
---
# To be used with aliBuild option `--defaults prod`.
#
# This is the default set used to produce centralized builds of AliRoot and
# AliPhysics.
#
#   * It is recommended on user laptops to use `--defaults user` instead
#   * If someone needs to use AliRoot/AliPhysics with GEANT3, 4 or DPMJET then
#     they can use this defaults set.
