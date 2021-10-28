package: MonALISA
version: "20211027"
requires:
 - JDK
build_requires:
 - alibuild-recipe-tools
---
curl http://alimonitor.cern.ch/download/MonaLisa/MonaLisa-${PKGVERSION}.tar.gz | tar xz --strip-components 1 -C $INSTALLROOT

mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > $INSTALLROOT/etc/modulefiles/$PKGNAME
