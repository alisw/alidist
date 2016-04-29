package: ZeroMQ
version: master
source: https://github.com/ktf/libzmq
tag: master
requires:
  - sodium
  - "GCC-Toolchain:(?!osx)"
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"zmq.h\"\n" | gcc -I$(brew --prefix zeromq)/include -xc++ - -c -M 2>&1
---
#!/bin/sh
cd $SOURCEDIR
./autogen.sh 
cd $BUILDDIR
$SOURCEDIR/configure --prefix=$INSTALLROOT \
                     --disable-dependency-tracking \
                     sodium_CFLAGS="-I$SODIUM_ROOT/include" \
                     sodium_LIBS="-L$SODIUM_ROOT/lib -lsodium"

make ${JOBS+-j $JOBS}
make install

# Modulefile
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
module load BASE/1.0 ${SODIUM_ROOT:+sodium/$SODIUM_VERSION-$SODIUM_REVISION} ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv ZEROMQ_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(ZEROMQ_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ZEROMQ_ROOT)/lib")
EoF
