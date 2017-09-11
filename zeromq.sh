package: ZeroMQ
version: v4.1.5
source: https://github.com/alisw/zeromq
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - autotools
prefer_system: (?!slc5.*)
prefer_system_check: |
  printf "#include <zmq.h>\n#if(ZMQ_VERSION < 40103)\n#error \"zmq version >= 4.1.3 needed\"\n#endif\n int main(){}" | gcc -I$(brew --prefix zeromq)/include $([[ -d $(brew --prefix zeromq) ]] || echo "-l:libzmq.a") -xc++ - -o /dev/null 2>&1
---
#!/bin/sh

# Hack to avoid having to do autogen inside $SOURCEDIR
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
cd $BUILDDIR
./autogen.sh

# Set the environment variables CC and CXX if a compiler is defined in the defaults file
# In case CC and CXX are defined the corresponding compilers are used during compilation
[[ -z "$CXX_COMPILER" ]] || export CXX=$CXX_COMPILER
[[ -z "$C_COMPILER" ]] || export CC=$C_COMPILER

./configure --prefix=$INSTALLROOT          \
            --disable-dependency-tracking

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
