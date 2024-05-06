package: defaults-o2-dataflow
version: v1
env:
  CFLAGS: "-fPIC -O2"
  CXXFLAGS: "-fPIC -O2 -std=c++20"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "20"
  ENABLE_VMC: 'ON'
  MACOSX_DEPLOYMENT_TARGET: '10.15'
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
  - pythia
  - pythia6
  - hijing
  - HepMC3
  - XRootD
  - xjalienfs
  - JAliEn-ROOT
  - KFParticle
  - MCStepLogger
  - O2sim
  - O2-full-system-test
  - O2Physics
  # Fall back to the system OpenSSL and curl.
  - OpenSSL
  - curl:(?!osx.*)
overrides:
  GCC-Toolchain:
    version: "v12.2.0-alice1"
    tag: "v12.2.0-alice1"
  Python-modules-list:
    env:
      PIP_BASE_REQUIREMENTS: |
        pip == 21.3.1; python_version < '3.12'
        pip == 24.0; python_version >= '3.12'
        setuptools == 59.6.0; python_version < '3.12'
        setuptools == 69.1.0; python_version >= '3.12'
        wheel == 0.37.1; python_version < '3.12'
        wheel == 0.42.0; python_version >= '3.12'
      PIP_REQUIREMENTS: |
        requests == 2.27.1; python_version < '3.11'
        requests == 2.31.0; python_version >= '3.11'
        responses == 0.10.6
        dryable == 1.0.3; python_version < '3.9'
        dryable == 1.0.5; python_version >= '3.9'
  O2-customization:
    env:
      ENABLE_UPGRADES: "OFF"  # Disable detector upgrades in O2
      BUILD_ANALYSIS: "OFF"   # Disable analysis in O2
      BUILD_EXAMPLES: "OFF"   # Disable examples in O2
      O2_BUILD_FOR_FLP: "ON"
  DataDistribution:
    requires:
      - "GCC-Toolchain:(?!osx)"
      - boost
      - FairLogger
      - libInfoLogger
      - FairMQ
      - Ppconsul
      - grpc
      - Monitoring
      - protobuf
      - O2
      - fmt
      - ucx   # this one added
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
