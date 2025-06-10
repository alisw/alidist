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
  - JAliEn-ROOT
  - ApMon-CPP
  - ZeroMQ:(osx.*)
build_requires:
  - CMake
  - "Xcode:(osx.*)"
env:
  ALICE_ROOT: "$ALIROOT_ROOT"
prepend_path:
  ROOT_INCLUDE_PATH: "$ALIROOT_ROOT/include"
source: https://github.com/alisw/AliRoot
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}
  cp -v ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
  DEVEL_SOURCES="$(readlink "$SOURCEDIR" || echo "$SOURCEDIR")"
  if [[ $DEVEL_SOURCES != $SOURCEDIR ]]; then
    sed -i.deleteme -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
    rm -f compile_commands.json.deleteme
    ln -nfs "$BUILDDIR/compile_commands.json" "$DEVEL_SOURCES/compile_commands.json"
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

FVERSION=`gfortran --version | grep -i fortran | sed -e 's/.* //' | cut -d. -f1`
SPECIALFFLAGS=""
if [ $FVERSION -ge 10 ]; then
   echo "Fortran version $FVERSION"
   SPECIALFFLAGS=1
fi
# Use ninja if in devel mode, ninja is found and DISABLE_NINJA is not 1
if [[ ! $CMAKE_GENERATOR && $DISABLE_NINJA != 1 && $DEVEL_SOURCES != $SOURCEDIR ]]; then
  NINJA_BIN=ninja-build
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=ninja
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=
  # AliRoot contains Fortran code, which requires at least ninja v1.10
  # in order to build with ninja, otherwise the build must fall back to make
  NINJA_VERSION_MAJOR=0
  NINJA_VERSION_MINOR=0
  if [ "x$NINJA_BIN" != "x" ]; then
    NINJA_VERSION_MAJOR=$($NINJA_BIN --version | sed -e 's/.* //' | cut -d. -f1)
    NINJA_VERSION_MINOR=$($NINJA_BIN --version | sed -e 's/.* //' | cut -d. -f2)
  fi
  NINJA_VERSION=$(($NINJA_VERSION_MAJOR * 100 + $NINJA_VERSION_MINOR))
  [[ $NINJA_BIN && $NINJA_VERSION -ge 110 ]] && CMAKE_GENERATOR=Ninja || true
  unset NINJA_BIN
fi

cmake $SOURCEDIR                                                     \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-Wno-error -g"               \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                          \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                             \
      -DCMAKE_Fortran_COMPILER=gfortran                              \
      -DROOTSYS="$ROOT_ROOT"                                         \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"}                      \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"}    \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN="$ALIEN_RUNTIME_ROOT"}           \
      ${JALIEN_ROOT_ROOT:+-DJALIEN_LIBS=$JALIEN_ROOT_ROOT}           \
      ${ALIEN_ROOT_LEGACY_ROOT:+-DALIEN_LIBS=$ALIEN_ROOT_LEGACY_ROOT}\
      ${FASTJET_ROOT:+-DFASTJET="$FASTJET_ROOT"}                     \
      ${DPMJET_ROOT:+-DDPMJET="$DPMJET_ROOT"}                        \
      ${ZEROMQ_ROOT:+-DZEROMQ=$ZEROMQ_ROOT}                          \
      ${ALICE_DAQ:+-DDA=ON -DDARPM=ON -DdaqDA=$DAQ_DALIB}            \
      ${ALICE_DAQ:+-DAMORE_CONFIG=$AMORE_CONFIG}                     \
      ${ALICE_DAQ:+-DDATE_CONFIG=$DATE_CONFIG}                       \
      ${ALICE_DAQ:+-DDATE_ENV=$DATE_ENV}                             \
      ${ALICE_DAQ:+-DDIMDIR=$DAQ_DIM -DODIR=linux}                   \
      ${ALICE_SHUTTLE:+-DDIMDIR=$HOME/dim -DODIR=linux}              \
      ${ALICE_SHUTTLE:+-DSHUTTLE=ON -DApMon=$APMON_ROOT}             \
      -DOCDB_INSTALL=PLACEHOLDER                                     \
      ${SPECIALFFLAGS:+-DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch"}

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install
# ctest will succeed if no load_library tests were found
ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}
[[ $ALICE_DAQ && ! $ALICE_DISABLE_DA_RPMS ]] && { make daqDA-all-rpm && make ${JOBS+-j $JOBS} install; }

# Copy the compile commands in the installation and source directory (only if devel mode!)
cp -v compile_commands.json ${INSTALLROOT}
DEVEL_SOURCES="$(readlink "$SOURCEDIR" || echo "$SOURCEDIR")"
if [[ $DEVEL_SOURCES != $SOURCEDIR ]]; then
  sed -i.deleteme -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  rm -f compile_commands.json.deleteme
  ln -nfs "$BUILDDIR/compile_commands.json" "$DEVEL_SOURCES/compile_commands.json"
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
module load BASE/1.0                                                                                                \\
            ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}                                                     \\
            ${DPMJET_REVISION:+DPMJET/$DPMJET_VERSION-$DPMJET_REVISION}                                             \\
            ${FASTJET_REVISION:+fastjet/$FASTJET_VERSION-$FASTJET_REVISION}                                         \\
            ${GEANT3_REVISION:+GEANT3/$GEANT3_VERSION-$GEANT3_REVISION}                                             \\
            ${ZEROMQ_REVISION:+ZeroMQ/$ZEROMQ_VERSION-$ZEROMQ_REVISION}                                             \\
            ${GEANT4_VMC_REVISION:+GEANT4_VMC/$GEANT4_VMC_VERSION-$GEANT4_VMC_REVISION}                             \\
            ${VC_REVISION:+Vc/$VC_VERSION-$VC_REVISION}                                                             \\
            ${JALIEN_ROOT_REVISION:+JAliEn-ROOT/$JALIEN_ROOT_VERSION-$JALIEN_ROOT_REVISION}                         \\
            ${ALIEN_ROOT_LEGACY_REVISION:+AliEn-ROOT-Legacy/$ALIEN_ROOT_LEGACY_VERSION-$ALIEN_ROOT_LEGACY_REVISION}
# Our environment
set ALIROOT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv ALIROOT_VERSION \$version
setenv ALICE \$::env(BASEDIR)/$PKGNAME
setenv ALIROOT_RELEASE \$::env(ALIROOT_VERSION)
set ALICE_ROOT \$::env(BASEDIR)/$PKGNAME/\$::env(ALIROOT_RELEASE)
setenv ALICE_ROOT \$ALICE_ROOT
prepend-path PATH \$ALICE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ALICE_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$ALICE_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$ALICE_ROOT/include/Pythia8
prepend-path ROOT_DYN_PATH \$ALICE_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
