package: JAliEn-ROOT
version: "%(tag_basename)s"
tag: "integration"
source: https://gitlab.cern.ch/dberzano/jalien-root
requires:
  - ROOT
build_requires:
  - libwebsockets
  - json-c
  - CMake
  - "GCC-Toolchain:(?!osx)"
append_path:
  ROOT_PLUGIN_PATH: "$JALIEN_ROOT_ROOT/etc/plugins"
---
#!/bin/bash -e
cmake $SOURCEDIR                            \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DROOTSYS="$ROOTSYS"                  \
      -DJSONC="$JSON_C_ROOT"                \
      -DLWS="$LWS_ROOT"
make ${JOBS:+-j $JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ROOT/${ROOT_VERSION}-${ROOT_REVISION}

# Our environment
setenv JALIEN_ROOT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(JALIEN_ROOT_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(JALIEN_ROOT_ROOT)/lib
append-path ROOT_PLUGIN_PATH \$::env(JALIEN_ROOT_ROOT)/etc/plugins
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(JALIEN_ROOT_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
