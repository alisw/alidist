package: ApMon-CPP
version: "%(tag_basename)s"
tag: v2.2.8-alice6
source: https://github.com/alisw/apmon-cpp.git
build_requires:
  - "libtirpc:(?!osx)"
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --chmod=ug=rwX --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./
autoreconf -ivf

if [[ -n ${LIBTIRPC_ROOT} ]];
then
  export CXXFLAGS="${CXXFLAGS} -I${LIBTIRPC_ROOT}/include/tirpc"
  export LDFLAGS="${LDFLAGS} -ltirpc -L${LIBTIRPC_ROOT}/lib"
fi

./configure --prefix=$INSTALLROOT
make ${JOBS:+-j$JOBS}
make install

find $INSTALLROOT -name '*.la' -delete

# Modules
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
module load BASE/1.0 \\
       ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set APMON_CPP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$APMON_CPP_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
