package: defaults-o2-dev-fairroot
version: v1
env:
  CXXFLAGS: "-fPIC -O2 -std=c++17"
  CFLAGS: "-fPIC -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "17"
  CMAKE_GENERATOR: "Ninja"
  GEANT4_BUILD_MULTITHREADED: "ON"
disable:
  - AliEn-Runtime
  - AliRoot
overrides:
  ROOT:
    build_requires:
      - CMake
      - "Xcode:(osx.*)"
      - ninja
  Ppconsul:
    build_requires:
      - CMake
      - ninja
  O2:
    version: "%(short_hash)s%(defaults_upper)s"
    tag: dev
    build_requires:
      - lcov
      - ninja
      - RapidJSON
      - googlebenchmark
      - AliGPU
      - cub
  FairRoot:
    version: dev
    tag: dev
    source: https://github.com/FairRootGroup/FairRoot
    build_requires:
      - googletest
      - ninja
  FairMQ:
    version: dev
    tag: dev
    source: https://github.com/FairRootGroup/FairMQ
  msgpack:
    version: "v3.1.1"
    tag: cpp-3.1.1
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
