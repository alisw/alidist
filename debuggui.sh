package: DebugGUI
version: "v0.1.0-%(short_hash)s"
tag: 62111ab1a7673601cd934b0b30ac38a5e4f2aec5
requires:
  - "GCC-Toolchain:(?!osx)"
  - GLFW
build_requires:
  - CMake
source: https://github.com/AliceO2Group/DebugGUI
---
case $ARCHITECTURE in
    osx*)
      [[ ! $GLFW_ROOT ]] && GLFW_ROOT=`brew --prefix glfw`
    ;;
esac

cmake $SOURCEDIR                          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

cmake --build . -- ${JOBS+-j $JOBS} install

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
module load BASE/1.0  ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${GLFW_REVISION:+GLFW/$GLFW_VERSION-$GLFW_REVISION}

# Our environment
set DEBUGGUI_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$DEBUGGUI_ROOT/bin
prepend-path LD_LIBRARY_PATH \$DEBUGGUI_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
