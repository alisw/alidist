package: defaults-user
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-02h
    requires:
      - ROOT
      - fastjet:(?!.*ppc64)
      - Vc
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-02h-01
---
# To be used with aliBuild option `--defaults user`.
#
# This defaults set is meant to be used on user computers.
#
#   * Builds AliRoot and AliPhysics without GEANT3, 4 and DPMJET, which fits
#     most of the use cases and speeds up compilation time dramatically
#   * Pinpoints AliRoot and AliPhysics to their latest tags, but they will be
#     overridden by using packages in development mode
#
# This defaults set will become the default and will replace "release" at some
# point.
