package: c-ares
version: "1.34.6"
tag: v1.34.6
license: MIT
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
source: https://github.com/c-ares/c-ares
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
prepend_path:
  PKG_CONFIG_PATH: "$C_ARES_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

# HAVE_PIPE2 is pre-seeded rather than probed. CHECK_SYMBOL_EXISTS only asks whether
# the symbol is declared, which it is on the macOS 27 SDK, where pipe2() is marked as
# introduced in 27.0. With MACOSX_DEPLOYMENT_TARGET below that, the unguarded call in
# src/lib/event/ares_event_wake_pipe.c is a -Wunguarded-availability-new error. The
# #else branch there is plain pipe() + fcntl(O_NONBLOCK), so nothing is lost.
cmake $SOURCEDIR -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DCMAKE_INSTALL_LIBDIR=lib -DHAVE_PIPE2=OFF
make ${JOBS:+-j$JOBS} install

case $ARCHITECTURE in
  osx*)
    # Add correct rpath to dylibs on Mac as long as there is no better way to
    # control rpath in the GRPC CMake
    # Add rpath to all libraries in lib and change their IDs to be absolute paths.
    find "$INSTALLROOT/lib" -name '*.dylib' -not -name '*ios*.dylib' \
         -exec install_name_tool -id '{}' '{}' \;
  ;;
esac

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
module load BASE/1.0
# Our environment
set C_ARES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$C_ARES_ROOT/bin
prepend-path LD_LIBRARY_PATH \$C_ARES_ROOT/lib
EoF
