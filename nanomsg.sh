package: nanomsg
version: v1.0.0
source: https://github.com/nanomsg/nanomsg
tag: 1.0.0
build_requires:
  - CMake
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include \"nanomsg/nn.h\"\nint main(){}" | cc -I$(brew --prefix nanomsg)/include -Wno-deprecated-declarations -xc - -o /dev/null
---
#!/bin/sh
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}"
make ${JOBS+-j $JOBS}
make test
make install

# Modulefile support
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
setenv NANOMSG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(NANOMSG_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(NANOMSG_ROOT)/lib")
prepend-path PATH \$::env(NANOMSG_ROOT)/bin
EoF
