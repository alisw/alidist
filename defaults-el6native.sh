package: defaults-el6native
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++98"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"

disable:
  - AliEn-Runtime
  - GCC-Toolchain

overrides:
  AliRoot:
    requires:
      - ROOT
    build_requires:
      - CMake
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
