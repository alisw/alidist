package: AliRoot
version: "%(commit_hash)s%(defaults_upper)s"
requires:
  - ROOT
  - DPMJET
  - fastjet:(?!.*ppc64)
  - GEANT3
  - GEANT4_VMC
  - Vc
build_requires:
  - CMake
  - "Xcode:(osx.*)"
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
prepend_path:
  ROOT_INCLUDE_PATH: "$ALIROOT_ROOT/include"
source: https://github.com/alisw/AliRoot
tag: master
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}
  rsync -a $SOURCEDIR/test/ $INSTALLROOT/test
  [[ $CMAKE_BUILD_TYPE == COVERAGE ]] && mkdir -p "$WORK_DIR/$ARCHITECTURE/profile-data/AliRoot/$PKGVERSION-$PKGREVISION/" && rsync -acv --filter='+ */' --filter='+ *.cpp' --filter='+ *.cc' --filter='+ *.h' --filter='+ *.gcno' --filter='- *' "$BUILDDIR/" "$WORK_DIR/$ARCHITECTURE/profile-data/AliRoot/$PKGVERSION-$PKGREVISION/"
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

# Picking up ROOT from the system when ours is disabled
[[ -z "$ROOT_ROOT" ]] && ROOT_ROOT="$(root-config --prefix)"

# If building DAQ utilities verify environment integrity
[[ $ALICE_DAQ ]] && ( source /date/setup.sh )

# Generates an environment file to be loaded in case we need code coverage
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
mkdir -p $INSTALLROOT/etc
cat << EOF > $INSTALLROOT/etc/gcov-setup.sh
export GCOV_PREFIX=${GCOV_PREFIX:-"$WORK_DIR/${ARCHITECTURE}/profile-data/AliRoot/$PKGVERSION-$PKGREVISION"}
export GCOV_PREFIX_STRIP=$(echo $INSTALLROOT | sed -e 's|/$||;s|^/||;s|//*|/|g;s|[^/]||g' | wc -c | sed -e 's/[^0-9]*//')
EOF
source $INSTALLROOT/etc/gcov-setup.sh
fi

cmake $SOURCEDIR                                                     \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                          \
      -DROOTSYS="$ROOT_ROOT"                                         \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"}    \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN="$ALIEN_RUNTIME_ROOT"}           \
      ${FASTJET_ROOT:+-DFASTJET="$FASTJET_ROOT"}                     \
      ${DPMJET_ROOT:+-DDPMJET="$DPMJET_ROOT"}                        \
      ${ZEROMQ_ROOT:+-DZEROMQ=$ZEROMQ_ROOT}                          \
      ${ALICE_DAQ:+-DDA=ON -DDARPM=ON -DdaqDA=$DAQ_DALIB}            \
      ${ALICE_DAQ:+-DAMORE_CONFIG=$AMORE_CONFIG}                     \
      ${ALICE_DAQ:+-DDATE_CONFIG=$DATE_CONFIG}                       \
      ${ALICE_DAQ:+-DDATE_ENV=$DATE_ENV}                             \
      ${ALICE_DAQ:+-DDIMDIR=$DAQ_DIM -DODIR=linux}                   \
      ${ALICE_SHUTTLE:+-DDIMDIR=$HOME/dim -DODIR=linux}              \
      ${ALICE_SHUTTLE:+-DSHUTTLE=ON -DApMon=$ALIEN_RUNTIME_ROOT}     \
      -DOCDB_INSTALL=PLACEHOLDER

make ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install
# ctest will succeed if no load_library tests were found
ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}
[[ $ALICE_DAQ && ! $ALICE_DISABLE_DA_RPMS ]] && { make daqDA-all-rpm && make ${JOBS+-j $JOBS} install; }

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
module load BASE/1.0 ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION} ${DPMJET_VERSION:+DPMJET/$DPMJET_VERSION-$DPMJET_REVISION} ${FASTJET_VERSION:+fastjet/$FASTJET_VERSION-$FASTJET_REVISION} ${GEANT3_VERSION:+GEANT3/$GEANT3_VERSION-$GEANT3_REVISION} ${GEANT4_VMC_VERSION:+GEANT4_VMC/$GEANT4_VMC_VERSION-$GEANT4_VMC_REVISION} ${VC_VERSION:+Vc/$VC_VERSION-$VC_REVISION}
# Our environment
setenv ALIROOT_VERSION \$version
setenv ALICE \$::env(BASEDIR)/$PKGNAME
setenv ALIROOT_RELEASE \$::env(ALIROOT_VERSION)
setenv ALICE_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ALIROOT_RELEASE)
prepend-path PATH \$::env(ALICE_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(ALICE_ROOT)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ALICE_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
