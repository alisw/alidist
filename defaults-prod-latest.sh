package: defaults-prod-latest
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-02p
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-02p-01
  # Use VMC packages compatible with ROOT 5
  GEANT3:
    version: "v2-7-p2"
    tag: "v2-7-p2"
  GEANT4_VMC:
    version: "v3-6-p6-inclxx-biasing-p5"
    tag: "v3-6-p6-inclxx-biasing-p5"
  GEANT4:
    source: https://github.com/alisw/geant4.git
    version: "v10.4.2-alice3"
    tag: "v10.4.2-alice3"
  vgm:
    version: "v4-4"
    tag: "v4-4"
---
# To be used with aliBuild option `--defaults prod-latest`.
#
# This is the default set used to produce centralized builds of AliRoot and
# AliPhysics, with pinpointed versions.
#
#   * It is recommended on user laptops to use `--defaults user` instead, which
#     pinpoints AliRoot and AliPhysics versions.
#   * Continuous integration tests use this defaults to test AliPhysics changes
#     against the latest tagged version of AliRoot.
