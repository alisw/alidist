package: defaults-jalien
version: v1
disable:
  - arrow
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  USE_AUTORECONF: "false"
overrides:
  AliRoot:
    version: "%(tag_basename)s_JALIEN"
    tag: v5-09-56w
  AliPhysics:
    version: "%(tag_basename)s_JALIEN"
    tag: v5-09-56w-01
  autotools:
    version: "%(tag_basename)s_JALIEN"
    tag: v1.5.0
  JAliEn-ROOT:
    version: "%(tag_basename)s"
    tag: 0.6.1
  Alice-GRID-Utils:
    version: "%(tag_basename)s"
    tag: 0.0.7
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

