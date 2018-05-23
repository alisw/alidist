package: AliPhysics
version: "%(commit_hash)s"
tag: master
requires:
  - AliRoot
build_requires:
  - "Xcode:(osx.*)"
source: https://github.com/alisw/AliPhysics
env:
  ALICE_PHYSICS: "$ALIPHYSICS_ROOT"
prepend_path:
  ROOT_INCLUDE_PATH: "$ALIPHYSICS_ROOT/include"
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  ctest -R load_library --output-on-failure ${JOBS:+-j $JOBS}
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

cmake "$SOURCEDIR"                                                 \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                        \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                           \
      -DROOTSYS="$ROOT_ROOT"                                       \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"}  \
      ${ALIEN_RUNTIME_ROOT:+-DALIEN="$ALIEN_RUNTIME_ROOT"}         \
      ${FASTJET_ROOT:+-DFASTJET="$FASTJET_ROOT"}                   \
      ${CGAL_ROOT:+-DCGAL="$CGAL_ROOT"}                            \
      ${MPFR_ROOT:+-DMPFR="$MPFR_ROOT"}                            \
      ${GMP_ROOT:+-DGMP="$GMP_ROOT"}                               \
      -DALIROOT="$ALIROOT_ROOT"

make ${IGNORE_ERRORS:+-k} ${JOBS+-j $JOBS} install
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
module load BASE/1.0 AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION
# Our environment
setenv ALIPHYSICS_VERSION \$version
setenv ALIPHYSICS_RELEASE \$::env(ALIPHYSICS_VERSION)
setenv ALICE_PHYSICS \$::env(BASEDIR)/$PKGNAME/\$::env(ALIPHYSICS_RELEASE)
prepend-path PATH \$::env(ALICE_PHYSICS)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALICE_PHYSICS)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(ALICE_PHYSICS)/include
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ALICE_PHYSICS)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
