package: MonALISA
version: "20210818"
# tag: "1.0.0"
# source: https://gitlab.cern.ch/jalien/jalien.git
requires:
 - JDK
 - "curl:(?!slc8)"
 - "system-curl:slc8.*"
valid_defaults:
 - monalisa
---
#!/bin/bash -e

curl http://alimonitor.cern.ch/download/MonaLisa/MonaLisa-${PKGVERSION}.tar.gz | tar xz
mkdir $INSTALLROOT/$PKGVERSION-$PKGREVISION
mv MonaLisa-$PKGVERSION $INSTALLROOT/$PKGVERSION-$PKGREVISION

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
module load BASE/1.0 JDK/$JDK_VERSION-$JDK_REVISION \\
            XRootD/$XROOTD_VERSION-$XROOTD_REVISION \\
            xjalienfs/$XJALIENFS_VERSION-$XJALIENFS_REVISION
# Our environment
set JALIEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path CLASSPATH \$JALIEN_ROOT/lib/alien-users.jar
prepend-path PATH \$JALIEN_ROOT/bin
EoF
