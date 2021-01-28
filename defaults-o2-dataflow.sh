package: defaults-o2-dataflow
version: v21.05
env:
  CXXFLAGS: "-fPIC -O2 -std=c++17"
  CFLAGS: "-fPIC -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "17"
disable:
  - AEGIS
  - AliEn-Runtime
  - AliRoot
  - ApMon-CPP
  - cgal
  - simulation
  - fastjet
  - generators
  - GEANT4
  - GEANT3
  - GEANT4_VMC
  - libjalienO2
  - pythia
  - pythia6
  - hijing
  - HepMC3
  - XRootD
  - xjalienfs
  - JAliEn-ROOT
  - KFParticle
  - MCStepLogger
overrides:
  Python-modules-list:
    env:
      PIP_REQUIREMENTS: |
        requests==2.21.0
        dryable==1.0.3
        responses==0.10.6
        PyYAML==5.1
  cub:
    version: v21.05
  fmt:
    version: v21.05
  alibuild-recipe-tools:
    version: v21.05
  flatbuffers:
    version: v21.05
  googlebenchmark:
    version: v21.05
  O2-customization:
    version: v21.05
  re2:
    version: v21.05
  Python-modules-list:
    version: v21.05
  protobuf:
    version: v21.05
  ms_gsl:
    version: v21.05
  Clang:
    version: v21.05
  GMP:
    version: v21.05
  googletest:
    version: v21.05
  ofi:
    version: v21.05
  RapidJSON:
    version: v21.05
  double-conversion:
    version: v21.05
  libwebsockets:
    version: v21.05
  FairLogger:
    version: v21.05
  Vc:
    version: v21.05
  curl:
    version: v21.05
  capstone:
    version: v21.05
  boost:
    version: v21.05
  GLFW:
    version: v21.05
  utf8proc:
    version: v21.05
  libuv:
    version: v21.05
  Python-modules:
    version: v21.05
  MPFR:
    version: v21.05
  Ppconsul:
    version: v21.05
  Common-O2:
    version: v21.05
  Monitoring:
    version: v21.05
  yaml-cpp:
    version: v21.05
  libInfoLogger:
    version: v21.05
  asiofi:
    version: v21.05
  arrow:
    version: v21.05
  DebugGUI:
    version: v21.05
  Configuration:
    version: v21.05
  FairMQ:
    version: v21.05
  ROOT:
    version: v21.05
  MCStepLogger:
    version: v21.05
  FairRoot:
    version: v21.05
  O2:
    version: v21.05
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
