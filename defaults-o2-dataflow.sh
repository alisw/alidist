package: defaults-o2-dataflow
version: v1
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
  - O2sim
  - O2-full-system-test
overrides:
  Python-modules-list:
    env:
      PIP_REQUIREMENTS: |
        requests==2.21.0
        dryable==1.0.3
        responses==0.10.6
        PyYAML==5.1
  O2-customization:
    env:
      ENABLE_UPGRADES: OFF # Disable detector upgrades in O2
      BUILD_ANALYSIS: OFF # Disable analysis in O2
      BUILD_EXAMPLES: OFF # Disable examples in O2
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
