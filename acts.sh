package: ACTS
version: "main"
requires:
  - ROOT
  - pythia
  - GEANT4
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - HepMC3
  - boost
  - Eigen3
  - alibuild-recipe-tools
  - ninja
source: https://github.com/AliceO2Group/acts.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE                   \
                 -DACTS_BUILD_FATRAS=ON                    \
                 -DACTS_BUILD_EXAMPLES=ON                  \
                 -DACTS_BUILD_EXAMPLES_PYTHON_BINDINGS=ON  \
		 -DACTS_BUILD_ANALYSIS_APPS=ON             \
                 -DACTS_BUILD_EXAMPLES_PYTHIA8=ON          \
                 -DCMAKE_PREFIX_PATH=${PYTHIA_ROOT}  	   \
                 -DACTS_BUILD_PLUGIN_GEANT4=ON		   \
                 -DACTS_BUILD_FATRAS_GEANT4=ON		   \
                 -DACTS_BUILD_EXAMPLES_GEANT4=ON           \
		 -DGeant4_DIR=${GEANT4_ROOT}/lib           \
                 -G Ninja 

cmake --build . -- ${JOBS:+-j$JOBS} install

[[ -d $INSTALLROOT/lib64 ]] && [[ ! -d $INSTALLROOT/lib ]] && ln -sf ${INSTALLROOT}/lib64 $INSTALLROOT/lib

#ModuleFile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p ${MODULEDIR}
alibuild-generate-module --bin --lib > "${MODULEFILE}"
# extra environment
cat >> ${MODULEFILE} <<EOF
set ACTS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ACTS_ROOT \$ACTS_ROOT
prepend-path ROOT_INCLUDE_PATH \$ACTS_ROOT/include
EOF
