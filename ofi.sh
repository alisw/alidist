package: ofi
version: "%(tag_basename)s"
tag: "v1.7.1"
source: https://github.com/ofiwg/libfabric
build_requires:
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
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
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEDIR/$PKGNAME"
