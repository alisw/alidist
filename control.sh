package: Control
version: "v0.17.1"
requires:
  - Control-Core
  - Control-OCCPlugin
  - coconut
---
#!/bin/bash -e

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
            ${CONTROL_CORE_REVISION:+Control-Core/$CONTROL_CORE_VERSION-$CONTROL_CORE_REVISION} \\
            ${CONTROL_OCCPLUGIN_REVISION:+Control-OCCPlugin/$CONTROL_OCCPLUGIN_VERSION-$CONTROL_OCCPLUGIN_REVISION} \\
            ${COCONUT_REVISION:+coconut/$COCONUT_VERSION-$COCONUT_REVISION}

# Our environment
set Control_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$Control_ROOT/bin
prepend-path LD_LIBRARY_PATH \$Control_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
