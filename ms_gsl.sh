package: ms_gsl
version: "1"
tag: b014508
source: https://github.com/Microsoft/GSL.git
prepend_path:
  ROOT_INCLUDE_PATH: "$MS_GSL_ROOT/include"
---
#!/bin/bash -e

# recipe for the C++ guidelines support library (Microsoft implementation)
# can be deleted once we are fully C++17 compliant

# just rsync into the installdir since header only
rsync -a $SOURCEDIR/include $INSTALLROOT

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set osname [uname sysname]
setenv MS_GSL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$MS_GSL_ROOT/include
EoF
