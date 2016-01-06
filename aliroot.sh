package: AliRoot
version: "%(commit_hash)s%(defaults_upper)s"
requires:
  - ROOT
  - fastjet:(?!.*ppc64)
build_requires:
  - CMake
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot 
tag: master
incremental_recipe: make ${JOBS:+-j$JOBS} && make install && rsync -a $SOURCEDIR/test/ $INSTALLROOT/test
---
#!/bin/bash -e
if [ X`root-config --has-cxx11` = Xyes ]; then
  HAS_CPP11=true
fi

cmake $SOURCEDIR                                                  \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                         \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS ${HAS_CPP11:+-std=c++11}"      \
      -DROOTSYS=$ROOT_ROOT                                        \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"} \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN=$ALIEN_RUNTIME_ROOT}          \
      ${FASTJET_ROOT:+-DFASTJET=$FASTJET_ROOT}                    \
      -DOCDB_INSTALL=PLACEHOLDER

if [[ $GIT_TAG == master ]]; then
  make -k ${JOBS+-j $JOBS} install || true
else
  make ${JOBS+-j $JOBS} install
fi

rsync -av $SOURCEDIR/test/ $INSTALLROOT/test

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION ${FASTJET_VERSION:+fastjet/$FASTJET_VERSION-$FASTJET_REVISION}
# Our environment
setenv ALIROOT_VERSION \$version
setenv ALICE \$::env(BASEDIR)/$PKGNAME
setenv ALIROOT_RELEASE \$::env(ALIROOT_VERSION)
setenv ALICE_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ALIROOT_RELEASE)
prepend-path PATH \$::env(ALICE_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib
EoF
