package: go
version: v1.7.3
source: https://github.com/golang/go
tag: go1.7.3
---
#!/bin/sh

case $ARCHITECTURE in
	osx*)
		GOOS=darwin
		GOARCH=amd64
	;;
	*x86-64)
		GOOS=linux
		GOARCH=amd64
	;;
	*)
		GOOS=linux
		GOARCH=amd64
	;;
esac

mkdir ali-go-tmp
pushd ali-go-tmp
	TMP_FNAME=$GIT_TAG.$GOOS-$GOARCH.tar.gz
	curl -O -L https://golang.org/dl/${TMP_FNAME}
	tar zxf $TMP_FNAME
popd

/bin/cp -a ./ali-go-tmp/go/* $INSTALLROOT/.
/bin/rm -rf ali-go-tmp

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
setenv GOROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(GOROOT)/bin
EoF

