package: defaults-prod-latest
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-34
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-34-01
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
