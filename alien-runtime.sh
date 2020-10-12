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
 - ApMon-CPP
 - UUID
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set ALIEN_RUNTIME_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$ALIEN_RUNTIME_ROOT/lib
prepend-path PATH \$ALIEN_RUNTIME_ROOT/bin
setenv X509_CERT_DIR \$ALIEN_RUNTIME_ROOT/globus/share/certificates
EoF
