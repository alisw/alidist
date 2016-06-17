package: AliRoot
version: "%(commit_hash)s%(defaults_upper)s"
requires:
  - ROOT
  - fastjet:(?!.*ppc64)
  - GEANT3
  - GEANT4_VMC
build_requires:
  - CMake
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
source: http://git.cern.ch/pub/AliRoot
write_repo: https://git.cern.ch/reps/AliRoot
tag: master
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  rsync -a $SOURCEDIR/test/ $INSTALLROOT/test
  [[ $CMAKE_BUILD_TYPE == COVERAGE ]] && mkdir -p "$WORK_DIR/$ARCHITECTURE/profile-data/AliRoot/$PKGVERSION-$PKGREVISION/" && rsync -acv --filter='+ */' --filter='+ *.cpp' --filter='+ *.cc' --filter='+ *.h' --filter='+ *.gcno' --filter='- *' "$BUILDDIR/" "$WORK_DIR/$ARCHITECTURE/profile-data/AliRoot/$PKGVERSION-$PKGREVISION/"
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

# Picking up ROOT from the system when our is disabled
if [ "X$ROOT_ROOT" = X ]; then
  ROOT_ROOT="$(root-config --prefix)"
fi

# Generates an environment file to be loaded in case we need code coverage
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
mkdir -p $INSTALLROOT/etc
cat << EOF > $INSTALLROOT/etc/gcov-setup.sh
export GCOV_PREFIX=${GCOV_PREFIX:-"$WORK_DIR/${ARCHITECTURE}/profile-data/AliRoot/$PKGVERSION-$PKGREVISION"}
export GCOV_PREFIX_STRIP=$(echo $INSTALLROOT | sed -e 's|/$||;s|^/||;s|//*|/|g;s|[^/]||g' | wc -c | sed -e 's/[^0-9]*//')
EOF
source $INSTALLROOT/etc/gcov-setup.sh
fi

cmake $SOURCEDIR                                                  \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                       \
      -DROOTSYS="$ROOT_ROOT"                                      \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"} \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN="$ALIEN_RUNTIME_ROOT"}        \
      ${FASTJET_ROOT:+-DFASTJET="$FASTJET_ROOT"}                  \
      -DOCDB_INSTALL=PLACEHOLDER

if [[ $GIT_TAG == master ]]; then
  make -k ${JOBS+-j $JOBS} install || true
else
  make ${JOBS+-j $JOBS} install
fi

rsync -av $SOURCEDIR/test/ $INSTALLROOT/test

[[ $CMAKE_BUILD_TYPE == COVERAGE ]]                                                       \
  && mkdir -p "$WORK_DIR/${ARCHITECTURE}/profile-data/AliRoot/$PKGVERSION-$PKGREVISION/"  \
  && rsync -acv --filter='+ */' --filter='+ *.c' --filter='+ *.cxx' --filter='+ *.cpp' --filter='+ *.cc' --filter='+ *.hpp' --filter='+ *.h' --filter='+ *.gcno' --filter='- *' "$BUILDDIR/" "$WORK_DIR/${ARCHITECTURE}/profile-data/AliRoot/$PKGVERSION-$PKGREVISION/"

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} ${FASTJET_VERSION:+fastjet/$FASTJET_VERSION-$FASTJET_REVISION} ${GEANT3_VERSION:+GEANT3/$GEANT3_VERSION-$GEANT3_REVISION} ${GEANT4_VMC_VERSION:+GEANT4_VMC/$GEANT4_VMC_VERSION-$GEANT4_VMC_REVISION}
# Our environment
setenv ALIROOT_VERSION \$version
setenv ALICE \$::env(BASEDIR)/$PKGNAME
setenv ALIROOT_RELEASE \$::env(ALIROOT_VERSION)
setenv ALICE_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ALIROOT_RELEASE)
prepend-path PATH \$::env(ALICE_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
