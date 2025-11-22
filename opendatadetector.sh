package: OpenDataDetector
version: "main"
requires:
  - ROOT
  - pythia
  - GEANT4
  - HepMC3
build_requires:
  - "Clang:(?!osx)"
  - CMake
  - DD4Hep
  - libjalienO2
  - HepMC3
  - RapidJSON
  - libjalienO2
  - boost
  - Eigen3
  - ninja
  - alibuild-recipe-tools
source: https://gitlab.cern.ch/acts/OpenDataDetector.git
---
#!/bin/bash -ex

# Configure out-of-source, installing into $INSTALLROOT
cmake -S "$SOURCEDIR" -B ./ \
    -DDD4hep_DIR="$DD4HEP_ROOT" \
    -DGeant4_DIR="$GEANT4_ROOT" \
    -DROOT_DIR="$ROOTSYS" \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"

# Build
cmake --build . -- ${JOBS:+-j$JOBS}

cmake --install . --prefix "$INSTALLROOT"

# Some systems put libs in lib64/
[[ -d $INSTALLROOT/lib64 ]] && [[ ! -d $INSTALLROOT/lib ]] && ln -sf "$INSTALLROOT/lib64" "$INSTALLROOT/lib"

# ModuleFile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p "${MODULEDIR}"
alibuild-generate-module --bin --lib >"${MODULEFILE}"

# extra environment
cat >>"${MODULEFILE}" <<EOF
set ODD_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ODD_ROOT \$ODD_ROOT
prepend-path ROOT_INCLUDE_PATH \$ODD_ROOT/include
EOF
