package: defaults-coverage
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -fprofile-arcs -ftest-coverage"
  CFLAGS: "-fPIC -g -O2 -fprofile-arcs -ftest-coverage"
  CMAKE_BUILD_TYPE: Coverage
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
