package: msgpack
version: v3.1.1
tag: cpp-v3.1.1
source: https://github.com/msgpack/msgpack-c
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <msgpack/version.hpp>\n#define VERSION (MSGPACK_VERSION_MAJOR * 10000) + (MSGPACK_VERSION_MINOR * 100) + MSGPACK_VERSION_REVISION\n#if(VERSION < 20105)\n#error \"msgpack version >= 2.1.5 needed\"\n#endif\nint main(){}" | c++ -I$(brew --prefix msgpack)/include -xc++ -std=c++11 - -o /dev/null
---
mkdir -p $INSTALLROOT

cmake $SOURCEDIR                                                 \
      ${C_COMPILER:+-DCMAKE_C_COMPILER=$C_COMPILER}              \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER}        \
      -DMSGPACK_CXX11=ON                                         \
      -DMSGPACK_BUILD_TESTS=OFF                                  \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT

cmake --build . --target install ${JOBS:+-- -j$JOBS}

# ModuleFile
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
module load BASE/1.0
# Our environment
setenv MSGPACK_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(MSGPACK_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(MSGPACK_ROOT)/lib")
EoF
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p $MODULEDIR && rsync -a --delete etc/modulefiles/ $MODULEDIR
