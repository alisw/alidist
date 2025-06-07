package: AliEn-Runtime
version: "v2-19-le"
requires:
  - "GCC-Toolchain:(?!osx)"
  - "Xcode:(osx.*)"
build_requires:
  - zlib
  - libxml2
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - AliEn-CAs
  - UUID
  - alibuild-recipe-tools
env:
  X509_CERT_DIR: "$ALIEN_RUNTIME_ROOT/globus/share/certificates"
---
#!/bin/bash -e
for RPKG in $BUILD_REQUIRES; do
  RPKG_UP=$(echo $RPKG|tr '[:lower:]' '[:upper:]'|tr '-' '_')
  RPKG_ROOT=$(eval echo "\$${RPKG_UP}_ROOT")
  rsync -a $RPKG_ROOT/ $INSTALLROOT/
  pushd $INSTALLROOT/../../..
    env WORK_DIR=$PWD sh -e $INSTALLROOT/relocate-me.sh
  popd
  rm -f $INSTALLROOT/etc/modulefiles/{$RPKG,$RPKG.unrelocated} || true
done

rm -f $INSTALLROOT/lib/pkgconfig/zlib.pc

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEDIR/$PKGNAME"
cat >> "$MODULEDIR/$PKGNAME" <<\EoF
setenv X509_CERT_DIR $PKG_ROOT/globus/share/certificates
EoF
