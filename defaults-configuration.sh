package: defaults-configuration
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  protobuf:
    tag: "v3.0.2"
    version: "%(tag_basename)s"
  CMake:
    tag: "v3.5.2"
    prefer_system_check: |
      which cmake && case `cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3 | head -n1` in [0-2]*|3.[0-3].*|3.4.[0-2]) exit 1 ;; esac
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
