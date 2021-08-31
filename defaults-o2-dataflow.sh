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
env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++17
  CXXSTD: '17'
overrides:
  GCC-Toolchain:
    tag: v10.2.0-alice2
    version: v10.2.0-alice2
  O2:
    tag: dataflow-20210831
    version: '%(tag_basename)s'
  O2-customization:
    env:
      BUILD_ANALYSIS: false
      BUILD_EXAMPLES: false
      ENABLE_UPGRADES: false
  Python-modules-list:
    env:
      PIP36_REQUIREMENTS: 'python-consul==1.1.0

        psutil==5.8.0

        '
      PIP38_REQUIREMENTS: 'python-consul==1.1.0

        psutil==5.8.0

        '
      PIP39_REQUIREMENTS: 'python-consul==1.1.0

        psutil==5.8.0

        '
      PIP_REQUIREMENTS: 'requests==2.21.0

        dryable==1.0.3

        responses==0.10.6

        PyYAML==5.1

        python-consul==1.1.0

        psutil==5.8.0

        '
  protobuf:
    version: v3.14.0
package: defaults-o2-dataflow
version: v1

---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
