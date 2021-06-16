package: JAliEn
version: "%(tag_basename)s"
tag: "1.3.4"
source: https://gitlab.cern.ch/jalien/jalien.git
requires:
 - JDK
 - XRootD
 - xjalienfs
 - "curl:(?!slc8)"
 - "system-curl:slc8.*"
build_requires:
 - alibuild-recipe-tools
valid_defaults:
 - jalien
---
#!/bin/bash -e

rsync -av $SOURCEDIR/ ./
./compile.sh users
mkdir -p $INSTALLROOT/{bin,lib}
cp alien-users.jar $INSTALLROOT/lib/
rsync -av bin/ $INSTALLROOT/bin/

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --extra > "$MODULEDIR/$PKGNAME" <<\EoF
prepend-path CLASSPATH $PKG_ROOT/lib/alien-users.jar
EoF
