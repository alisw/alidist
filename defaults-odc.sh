package: defaults-odc
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
  FairMQ:
    tag: dev
    source: https://github.com/FairRootGroup/FairMQ/
  DDS:
    tag: master
    source: https://github.com/FairRootGroup/DDS
  grpc:
    tag: v1.24.3-p1
    source: https://github.com/FairRootGroup/grpc

---
