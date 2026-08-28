package: defaults-o2-acts
version: v1
env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
  ENABLE_VMC: 'ON'
  GEANT4_BUILD_MULTITHREADED: 'OFF'
  MACOSX_DEPLOYMENT_TARGET: '14.0'
disable:
  - mesos
  - MySQL
overrides:
  O2:
    requires:
        - abseil
        - arrow
        - FairRoot
        - Vc
        - HepMC3
        - libInfoLogger
        - Common-O2
        - Configuration
        - Monitoring
        - ms_gsl
        - FairMQ
        - curl
        - MCStepLogger
        - fmt
        - "openmp:(?!osx.*)"
        - DebugGUI
        - JAliEn-ROOT
        - fastjet
        - libuv
        - libjalienO2
        - cgal
        - "VecGeom:(?!osx.*)"
        - FFTW3
        - ONNXRuntime
        - nlohmann_json
        - MLModels
        - RapidJSON
        - bookkeeping-api
        - AliEn-CAs
        - gpu-system
        - Eigen3
        - GBL
        - ACTS
    build_requires:
        - abseil
        - GMP
        - MPFR
        - googlebenchmark
        - O2-customization
        - Clang:(?!osx*)
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
# 
# This defaults file enables ACTS for building ACTSO2.
# Usage: aliBuild build ACTSO2 --defaults o2-acts
