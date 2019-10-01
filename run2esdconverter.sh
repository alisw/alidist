package: Run2ESDConverter
version: "%(tag_basename)s"
tag: v0.1.2
requires:
  - arrow
  - ROOT
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
source: https://github.com/AliceO2Group/Run2ESDConverter
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

cmake $SOURCEDIR                                 \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}    \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT        \
      -DROOTSYS=$ROOTSYS                         \
      -DARROW_HOME=$ARROW_ROOT                   \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

pwd
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
module load BASE/1.0 ${ARROW_VERSION:+arrow/$ARROW_VERSION-$ARROW_REVISION} ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}  ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
set RUN2ESDCONVERTER_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$RUN2ESDCONVERTER_ROOT/bin
# Hope is that we do not need any LD_LIBRARY_PATH, actually
prepend-path LD_LIBRARY_PATH \$RUN2ESDCONVERTER_ROOT/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$RUN2ESDCONVERTER_ROOT/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
