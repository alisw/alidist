package: defaults-debug
version: v1
env:
  CXXFLAGS: "-fPIC -g -O0"
  CFLAGS: "-fPIC -g -O0"
  CMAKE_BUILD_TYPE: "DEBUG"
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
