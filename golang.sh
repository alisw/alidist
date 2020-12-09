package: golang
version: "1.15.6"
build_requires:
  - system-curl
prefer_system_check: |
  case `go version | sed -e 's/go version go//' | sed -e 's/ .*//'` in 0*|1.[0-9].*) exit 1 ;; esac
---
#!/bin/bash -e

ARCH=$(uname|tr '[:upper:]' '[:lower:]')-amd64
curl -LO https://golang.org/dl/go$PKGVERSION.$ARCH.tar.gz
tar --strip-components=1 -C $INSTALLROOT -xzf go$PKGVERSION.$ARCH.tar.gz

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
module load BASE/1.0

# Our environment
set GOROOT \$::env(BASEDIR)/$PKGNAME/\$version
# NOTE: upstream requires GOROOT to be defined if installing to a nonstandard path
prepend-path PATH \$GOROOT/bin
prepend-path LD_LIBRARY_PATH \$GOROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
