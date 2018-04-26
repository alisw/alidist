package: node
version: "v9.8.0"
build_requires:
  - curl
prefer_system: "(?!slc5)"
prefer_system_check: |
  which node || { echo "node is missing"; exit 1; }
  if [[ printf "%d%04d%04d" $(node --version | sed -e 's/v//g; s/\./ /g') -le 900090000 ]]; then echo "higher node version required"; exit 1; fi
---
#!/bin/bash

NODEOS=linux
case $ARCHITECTURE in
  osx*) NODEOS=darwin ;;
esac

FILE_NAME="$PKGNAME-$PKGVERSION-$NODEOS-x64"
TAR_NAME="$FILE_NAME.tar.gz"
URL="https://nodejs.org/dist/$PKGVERSION/$TAR_NAME"
curl -O -L $URL
tar zxf $TAR_NAME

rsync -a $FILE_NAME/ $INSTALLROOT/

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
setenv NODE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(NODE_ROOT)/bin
EoF
