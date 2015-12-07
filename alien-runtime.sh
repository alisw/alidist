package: AliEn-Runtime
version: "v2-19-le%(defaults_upper)s"
build_requires:
 - zlib
 - libxml2
 - "OpenSSL:(?!osx)"
 - AliEn-CAs
 - gSOAP
 - MonALISA-gSOAP-client
 - ApMon-CPP
 - XRootD
 - xalienfs
 - UUID
requires:
 - "GCC-Toolchain:(?!osx)"
prepend_path:
  PERLLIB: "$ALIEN_RUNTIME_ROOT/lib/perl"
env:
  GSHELL_ROOT: "$ALIEN_RUNTIME_ROOT"
  GSHELL_NO_GCC: "1"
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
done

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
setenv ALIEN_RUNTIME_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(ALIEN_RUNTIME_ROOT)/lib
prepend-path PATH \$::env(ALIEN_RUNTIME_ROOT)/bin
prepend-path PERLLIB \$::env(ALIEN_RUNTIME_ROOT)/lib/perl
setenv GSHELL_ROOT \$::env(ALIEN_RUNTIME_ROOT)
setenv X509_CERT_DIR \$::env(ALIEN_RUNTIME_ROOT)/globus/share/certificates
setenv GSHELL_NO_GCC 1
EoF
