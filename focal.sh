package: FOCAL
version: "%(commit_hash)s"
tag: v1.16
requires:
  - AliRoot
build_requires:
  - "Xcode:(osx.*)"
source: https://gitlab.cern.ch/mvl/FOCAL.git
env:
  FOCAL: "$FOCAL_ROOT"
prepend_path:
  ROOT_INCLUDE_PATH: "$FOCAL_ROOT/include"
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  cp -v compile_commands.json ${INSTALLROOT}
  DEVEL_SOURCES="$(readlink "$SOURCEDIR" || echo "$SOURCEDIR")"
  if [[ $DEVEL_SOURCES != $SOURCEDIR ]]; then
    sed -i.deleteme -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
    rm -f compile_commands.json.deleteme
    ln -nfs "$BUILDDIR/compile_commands.json" "$DEVEL_SOURCES/compile_commands.json"
  fi
  [[ $CMAKE_BUILD_TYPE == COVERAGE ]] && mkdir -p "$WORK_DIR/$ARCHITECTURE/profile-data/AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION/" && rsync -acv --filter='+ */' --filter='+ *.cpp' --filter='+ *.cc' --filter='+ *.h' --filter='+ *.gcno' --filter='- *' "$BUILDDIR/" "$WORK_DIR/$ARCHITECTURE/profile-data/AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION/"
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

# Picking up ROOT from the system when ours is disabled
[[ -z "$ROOT_ROOT" ]] && ROOT_ROOT="$(root-config --prefix)"

# Uses the same setup as AliRoot
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  source $ALIROOT_ROOT/etc/gcov-setup.sh
fi

# Use ninja if in devel mode, ninja is found and DISABLE_NINJA is not 1
if [[ ! $CMAKE_GENERATOR && $DISABLE_NINJA != 1 && $DEVEL_SOURCES != $SOURCEDIR ]]; then
  NINJA_BIN=ninja-build
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=ninja
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=
  # FOCAL contains Fortran code, which requires at least ninja v1.10
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

cmake "$SOURCEDIR/aliroot"                                         \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                        \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                           \
      -DROOTSYS="$ROOT_ROOT"                                       \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN="$ALIEN_RUNTIME_ROOT"}         \
      -DALIROOT="$ALIROOT_ROOT"

cmake --build . -- ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install
# ctest will succeed if no load_library tests were found
ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}

# Copy the compile commands in the installation and source directory (only if devel mode!)
cp -v compile_commands.json ${INSTALLROOT}
DEVEL_SOURCES="$(readlink "$SOURCEDIR" || echo "$SOURCEDIR")"
if [[ $DEVEL_SOURCES != $SOURCEDIR ]]; then
  sed -i.deleteme -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  rm -f compile_commands.json.deleteme
  ln -nfs "$BUILDDIR/compile_commands.json" "$DEVEL_SOURCES/compile_commands.json"
fi

[[ $CMAKE_BUILD_TYPE == COVERAGE ]]                                                       \
  && mkdir -p "$WORK_DIR/${ARCHITECTURE}/profile-data/AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION/"  \
  && rsync -acv --filter='+ */' --filter='+ *.c' --filter='+ *.cxx' --filter='+ *.cpp' --filter='+ *.cc' --filter='+ *.hpp' --filter='+ *.h' --filter='+ *.gcno' --filter='- *' "$BUILDDIR/" "$WORK_DIR/${ARCHITECTURE}/profile-data/AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION/"

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
module load BASE/1.0 AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION ${ROOUNFOLD_REVISION:+RooUnfold/$ROOUNFOLD_VERSION-$ROOUNFOLD_REVISION} ${TREELITE_REVISION:+treelite/$TREELITE_VERSION-$TREELITE_REVISION} ${KFPARTICLE_REVISION:+KFParticle/$KFPARTICLE_VERSION-$KFPARTICLE_REVISION}
# Our environment
setenv FOCAL_VERSION \$version
setenv FOCAL_RELEASE \$::env(FOCAL_VERSION)
set FOCAL \$::env(BASEDIR)/$PKGNAME/\$::env(FOCAL_RELEASE)
setenv FOCAL \$FOCAL
prepend-path PATH \$FOCAL/bin
prepend-path LD_LIBRARY_PATH \$FOCAL/lib
prepend-path ROOT_INCLUDE_PATH \$FOCAL/include
prepend-path ROOT_DYN_PATH \$FOCAL/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
