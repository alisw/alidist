package: Run2ESDConverter
version: "%(tag_basename)s"
tag: v0.1.4
requires:
  - arrow
  - ROOT
  - "GCC-Toolchain:(?!osx)"
  - ms_gsl
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Run2ESDConverter
incremental_recipe: |
  cd $BUILDDIR
  cmake --build . -- ${JOBS+-j $JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex
# Use ninja if in devel mode, ninja is found and DISABLE_NINJA is not 1
if [[ ! $CMAKE_GENERATOR && $DISABLE_NINJA != 1 && $DEVEL_SOURCES != $SOURCEDIR ]]; then
  NINJA_BIN=ninja-build
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=ninja
  type "$NINJA_BIN" &> /dev/null || NINJA_BIN=
  [[ $NINJA_BIN ]] && CMAKE_GENERATOR=Ninja || true
  unset NINJA_BIN
fi

cmake $SOURCEDIR                                \
      ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
      -DCMAKE_CXX_STANDARD=17                   \
      -DROOTSYS=$ROOTSYS                        \
      -DARROW_HOME=$ARROW_ROOT                  \
      -DMS_GSL_ROOT=$MS_GSL_ROOT                \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cd $BUILDDIR
cmake --build . -- ${JOBS+-j $JOBS} install

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

#ModuleFile
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
module load BASE/1.0 ${ARROW_REVISION:+arrow/$ARROW_VERSION-$ARROW_REVISION} \\
                     ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}     \\
                     ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
set RUN2ESDCONVERTER_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$RUN2ESDCONVERTER_ROOT/bin
# Hope is that we do not need any LD_LIBRARY_PATH, actually
prepend-path LD_LIBRARY_PATH \$RUN2ESDCONVERTER_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
