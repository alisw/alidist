package: ACTS
version: "v43.0.1"
requires:
  - ROOT
  - pythia
  - GEANT4
  - HepMC3
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - HepMC3
  - boost
  - Eigen3
  - ninja
  - alibuild-recipe-tools
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

# Print a message to remind people to source the ACTS python bindings
echo -e "\033[1mTo use the ACTS python bindings, source the following script:\033[0m"
echo ". $ACTS_ROOT/python/setup.sh"
