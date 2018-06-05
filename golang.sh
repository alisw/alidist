package: golang
version: "1.10.2"
build_requires:
  - curl
prefer_system_check: |
  which go && case `go version | sed -e 's/go version go//' | sed -e 's/ .*//'` in 0*|1.[0-9].*) exit 1 ;; esac
incremental_recipe: |
  case $ARCHITECTURE in
    osx*) ARCH=darwin-amd64 ;;
    *) ARCH=linux-amd64 ;;
  esac
  SOURCE=https://golang.org/dl/go$PKGVERSION.$ARCH.tar.gz
  curl -LO $SOURCE
  tar --strip-components=1 -C $INSTALLROOT -xzf go$PKGVERSION.$ARCH.tar.gz
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

case $ARCHITECTURE in
  osx*) ARCH=darwin-amd64 ;;
  *) ARCH=linux-amd64 ;;
esac

SOURCE=https://golang.org/dl/go$PKGVERSION.$ARCH.tar.gz
curl -LO $SOURCE
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
setenv GOROOT \$::env(BASEDIR)/$PKGNAME/\$version
# NOTE: upstream requires GOROOT to be defined if installing to a nonstandard path
prepend-path PATH \$::env(GOROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(GOROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(GOROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
