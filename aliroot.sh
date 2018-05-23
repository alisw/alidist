package: AliRoot
version: "%(commit_hash)s"
tag: master
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
  - AliTPCCommon
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
prepend_path:
  ROOT_INCLUDE_PATH: "$ALIROOT_ROOT/include"
source: https://github.com/alisw/AliRoot
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}
  cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
  DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
  # This really means we are in development mode. We need to make sure we
  # use the real path for sources in this case. We also copy the
  # compile_commands.json file so that IDEs can make use of it directly, this
  # is a departure from our "no changes in sourcecode" policy, but for a good reason
  # and in any case the file is in gitignore.
  if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
    perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
    ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
  fi
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
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                             \
      -DROOTSYS="$ROOT_ROOT"                                         \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"}    \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN="$ALIEN_RUNTIME_ROOT"}           \
      ${FASTJET_ROOT:+-DFASTJET="$FASTJET_ROOT"}                     \
      ${DPMJET_ROOT:+-DDPMJET="$DPMJET_ROOT"}                        \
      ${ZEROMQ_ROOT:+-DZEROMQ=$ZEROMQ_ROOT}                          \
      ${ALITPCCOMMON_ROOT:+-DALITPCCOMMON_DIR=$ALITPCCOMMON_ROOT}    \
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

# install the compilation database so that we can post-check the code
cp compile_commands.json ${INSTALLROOT}

DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
# This really means we are in development mode. We need to make sure we
# use the real path for sources in this case. We also copy the
# compile_commands.json file so that IDEs can make use of it directly, this
# is a departure from our "no changes in sourcecode" policy, but for a good reason
# and in any case the file is in gitignore.
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
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
