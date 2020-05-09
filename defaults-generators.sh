package: defaults-dev
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"

disable:
  - arrow

overrides:
  fastjet:
    version: "v3.3.3_1.042-alice1"
    tag: "v3.3.3_1.042-alice1"

  # Minimal boost with no Python & co. to avoid YODA asking for cython
  boost:
    requires:
      - "GCC-Toolchain:(?!osx)"

---
