package: protobuf
version: v3.5.2
source: https://github.com/google/protobuf
build_requires:
 - autotools
 - "GCC-Toolchain:(?!osx)"
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include \"google/protobuf/stubs/common.h\"\n#if (GOOGLE_PROTOBUF_VERSION < 3005000)\n#error \"At least protobuf 3.5.0 is required.\"\n#endif\nint main(){}" | c++ -I$(brew --prefix protobuf)/include -Wno-deprecated-declarations -xc++ - -o /dev/null && protoc -h &> /dev/null
---

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
autoreconf -ivf
./configure --prefix="$INSTALLROOT"
make ${JOBS:+-j $JOBS}
make install

#ModuleFile
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
setenv PROTOBUF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(PROTOBUF_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(PROTOBUF_ROOT)/lib")
prepend-path PATH \$::env(PROTOBUF_ROOT)/bin
EoF
