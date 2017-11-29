package: defaults-daq
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++98"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  ALICE_DAQ: "1"
  AMORE_CONFIG: /opt/amore/bin/amore-config
  DATE_CONFIG: /opt/date/.commonScripts/date-config
  DATE_ENV: /date/setup.sh
  DAQ_DIM: /opt/dim
  DAQ_DALIB: /opt/daqDA-lib

disable:
  - AliEn-Runtime
  - GCC-Toolchain

overrides:
  AliRoot:
    requires:
      - ROOT
    build_requires:
      - DAQ
      - CMake
  ROOT:
    requires: []
    build_requires:
      - CMake
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
