package: ofi
version: "%(tag_basename)s"
tag: "v1.7.1"
source: https://github.com/ofiwg/libfabric
build_requires:
  - autotools
prefer_system: ".*"
prefer_system_check: |
  pkg-config --atleast-version=1.6.0 libfabric 2>&1 && printf "#include \"rdma/fabric.h\"\nint main(){}" | c++ -xc - -o /dev/null
---
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./
autoreconf -ivf
./configure --prefix="$INSTALLROOT" --enable-mlx=no 
make ${JOBS:+-j $JOBS} install

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
module load BASE/1.0
# Our environment
set OFI_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv OFI_ROOT \$OFI_ROOT
prepend-path PATH \$OFI_ROOT/bin
prepend-path LD_LIBRARY_PATH \$OFI_ROOT/lib
EoF
