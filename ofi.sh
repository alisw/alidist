package: ofi
version: "%(tag_basename)s"
tag: v1.7.0
source: https://github.com/ofiwg/libfabric
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - autotools
prefer_system_check: |
  pkg-config --atleast-version=1.6.0 libfabric 2>&1
  if [ $? -ne 0 ]; then printf "libfabric was not found.\n * On RHEL-compatible systems you probably need: libfabric libfabric-devel\n * On Ubuntu-compatible systems you probably need: libfabric-bin libfabric-dev"; exit 1; fi
  printf "#include \"rdma/fabric.h\"\nint main(){}" | gcc -xc - -o /dev/null
  if [ $? -ne 0 ]; then printf "libfabric was not found.\n * On RHEL-compatible systems you probably need: libfabric libfabric-devel\n * On Ubuntu-compatible systems you probably need: libfabric-bin libfabric-dev"; exit 1; fi
---
rsync -a $SOURCEDIR/ ./
./autogen.sh
./configure --prefix=$INSTALLROOT --enable-verbs=yes --disable-mlx
make ${JOBS:+-j$JOBS}
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv OFI_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(OFI_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(OFI_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(OFI_ROOT)/lib")
EoF
