package: ACTSO2
version: "master"
tag: "master"
requires:
  - ROOT
  - ACTS
license: GPL-3.0
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - HepMC3
  - boost
  - Eigen3
  - ninja
  - alibuild-recipe-tools
source: ssh://git@gitlab.cern.ch:7999/alice3-trackers/wp1-simulationsandperformances/actso2.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
                 -DACTS_ROOT=$ACTS_ROOT \
                 -DCMAKE_PREFIX_PATH=$ACTS_ROOT
cmake --build . -- ${JOBS:+-j$JOBS}
cmake --install .

case $ARCHITECTURE in
    osx*)
        find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/python/acts {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${GEANT4_ROOT}/lib {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${XERCESC_ROOT}/lib {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${ROOT_DYN_PATH} {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${TBB_ROOT}/lib {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${HEPMC3_ROOT}/lib {} \;
        find $INSTALLROOT/python/actso2 -name "*.so" -exec install_name_tool -add_rpath ${PYTHIA_ROOT}/lib {} \;
	;;
esac

[[ -d $INSTALLROOT/lib64 ]] && [[ ! -d $INSTALLROOT/lib ]] && ln -sf ${INSTALLROOT}/lib64 $INSTALLROOT/lib

#ModuleFile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p ${MODULEDIR}
alibuild-generate-module --bin --lib > "${MODULEFILE}"
# extra environment
cat >> ${MODULEFILE} <<EOF
set ACTSO2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ACTSO2_ROOT \$ACTSO2_ROOT
prepend-path ROOT_INCLUDE_PATH \$ACTSO2_ROOT/include
EOF

# Print a message to remind people to source the ACTS python bindings
echo -e "\033[1mTo use the ACTS python bindings, source the following script:\033[0m"
echo ". $ACTS_ROOT/python/setup.sh"
