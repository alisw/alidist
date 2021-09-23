package: MonALISA
version: "20210818"
requires:
 - JDK
build_requires:
 - alibuild-recipe-tools
---
curl http://alimonitor.cern.ch/download/MonaLisa/MonaLisa-${PKGVERSION}.tar.gz | tar xz --strip-components 1 -C $INSTALLROOT

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin --lib > $INSTALLROOT/etc/modulefiles/$PKGNAME
cat >> "$INSTALLROOT/etc/modulefiles/$PKGNAME" <<EoF
prepend-path CLASSPATH \$JALIEN_ROOT/lib/alien-users.jar
EoF
