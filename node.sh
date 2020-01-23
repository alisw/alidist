package: node
version: "v12.13.0"
build_requires:
  - curl
prefer_system: "(?!slc5)"
prefer_system_check: |
  node -h &> /dev/null || { echo "node is missing"; exit 1; }
  if [[ $(printf "%d%04d%04d" $(node --version | sed -e 's/v//g; s/\./ /g')) -le 900090000 ]]; then echo "higher node version required"; exit 1; fi
---
#!/bin/bash

NODEOS=linux
case $ARCHITECTURE in
  osx*) NODEOS=darwin ;;
esac

FILE_NAME="$PKGNAME-$PKGVERSION-$NODEOS-x64"
URL="https://nodejs.org/dist/$PKGVERSION/$FILE_NAME.tar.gz"
curl -L $URL | tar xzf - --strip-components=1 -C $INSTALLROOT

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
set NODE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$NODE_ROOT/bin
EoF
