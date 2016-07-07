package: defaults-test
version: v1
env:
  CXXFLAGS: "-fPIC -g -O3 -std=c++11"
  CFLAGS: "-fPIC -g -O3"
  CMAKE_BUILD_TYPE: "RELEASE"
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
