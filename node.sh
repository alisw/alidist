package: node
version: "v8.11.1"
build_requires:
  - curl
---
#!/bin/bash

case $ARCHITECTURE in
	osx*)
		NODEOS=darwin
	;;
	*x86-64)
		NODEOS=linux
	;;
	*)
		NODEOS=linux
	;;
esac

FILE_NAME="$PKGNAME-$PKGVERSION-$NODEOS-x64"
mkdir ali-node-tmp
pushd ali-node-tmp
	TAR_NAME="$FILE_NAME.tar.gz"
	URL="https://nodejs.org/dist/$PKGVERSION/$TAR_NAME"	
	curl -O -L $URL
	tar zxf $TAR_NAME
popd

/bin/cp -a ./ali-node-tmp/$FILE_NAME/bin/* $INSTALLROOT/.
/bin/rm -rf ali-node-tmp

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
prepend-path PATH \$::env(NODE_ROOT)
EoF
