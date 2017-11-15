package: defaults-shuttle
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++0x"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  ALICE_SHUTTLE: "1"
  SHUTTLE_DIM: $HOME/dim

disable:
  - GCC-Toolchain
  - OpenSSL

overrides:
  AliRoot:
    requires:
      - ROOT
    build_requires:
      - CMake
  CMake:
    prefer_system_check: |
      which cmake && case `cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3 | head -n1` in [0-1]*|2.[0-7].*|2.8.[0-9]|2.8.1[0-1]) exit 1 ;; esac

---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
