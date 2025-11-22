package: DD4Hep
version: "master"
requires:
  - ROOT
build_requires:
  - "Clang:(?!osx)"
  - GEANT4
  - CMake
  - boost
  - ninja
  - alibuild-recipe-tools
source: https://github.com/AIDASoft/DD4hep.git
---
#!/bin/bash -ex

cmake $SOURCEDIR \
  -DBUILD_DOCS=OFF \
  -DDD4HEP_BUILD_DOCS=OFF \
  -DDD4HEP_USE_GEANT4=ON \
  -DBoost_NO_BOOST_CMAKE=ON \
  -DDD4HEP_USE_LCIO=OFF \
  -DBUILD_TESTING=ON \
  -DROOT_DIR=$ROOTSYS \
  -D CMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install

[[ -d $INSTALLROOT/lib64 ]] && [[ ! -d $INSTALLROOT/lib ]] && ln -sf ${INSTALLROOT}/lib64 $INSTALLROOT/lib

#ModuleFile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p ${MODULEDIR}
alibuild-generate-module --bin --lib > "${MODULEFILE}"
# extra environment
cat >> ${MODULEFILE} <<EOF
  set DD4HEP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
  setenv DD4HEP_ROOT \$DD4HEP_ROOT
  prepend-path ROOT_INCLUDE_PATH \$DD4HEP_ROOT/include
EOF
