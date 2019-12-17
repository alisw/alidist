package: ApMon-CPP
version: "%(tag_basename)s"
tag: v2.2.8-alice2
source: https://github.com/alisw/apmon-cpp.git
requires:
build_requires:
 - libtirpc
 - autotools
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded \
      $SOURCEDIR/ ./
autoreconf -ivf

# TODO: check if rpc.h really didn't come with glibc
if [[ -n ${LIBTIRPC_ROOT} ]];
then
  export CXXFLAGS="${CXXFLAGS} -I${LIBTIRPC_ROOT}/include/tirpc"
  export LDFLAGS="${LDFLAGS} -ltirpc -L${LIBTIRPC_ROOT}/lib"
fi

./configure --prefix=$INSTALLROOT
make ${JOBS:+-j$JOBS}
make install

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
setenv APMON_CPP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(APMON_CPP_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(APMON_CPP_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
