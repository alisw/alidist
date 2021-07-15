package: O2Physics
version: "%(tag_basename)s"
tag: "v0.0.1"
requires:
  - O2
source: https://github.com/AliceO2Group/O2Physics
---
#!/bin/sh
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"          \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                   \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"} \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}
cmake --build . -- ${JOBS+-j $JOBS} install
