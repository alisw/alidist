package: defaults-root6
version: v1
disable:
  - arrow
  - treelite
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  ROOT:
    tag: "v6-10-08"
  AliRoot:
    version: "%(commit_hash)s_ROOT6"
    tag: v5-09-20fb
  AliPhysics:
    version: "%(commit_hash)s_ROOT6"
    tag: v5-09-20fb-01
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
