package: AliEn-Runtime
version: "v2-19-le%(defaults_upper)s"
build_requires:
 - zlib
 - libxml2
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - AliEn-CAs
 - gSOAP
 - MonALISA-gSOAP-client
 - ApMon-CPP
 - XRootD
 - xalienfs
 - UUID
requires:
 - "GCC-Toolchain:(?!osx)"
 - "Xcode:(osx.*)"
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
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ALIEN_RUNTIME_ROOT)/lib")
prepend-path PATH \$::env(ALIEN_RUNTIME_ROOT)/bin
prepend-path PERLLIB \$::env(ALIEN_RUNTIME_ROOT)/lib/perl
setenv GSHELL_ROOT \$::env(ALIEN_RUNTIME_ROOT)
setenv X509_CERT_DIR \$::env(ALIEN_RUNTIME_ROOT)/globus/share/certificates
setenv GSHELL_NO_GCC 1
# check if Globus certificate is expiring soon
set CERT "$::env(HOME)/.globus/usercert.pem"
set status [catch {exec which openssl > /dev/null 2>&1} output]
if { $status == 0 } {
  if { [file isfile $CERT] } {
    set status [catch {exec openssl x509 -in "$CERT" -noout -checkend 0 > /dev/null 2>&1} output]
    if { $status == 1 } {
      set MSG "Your certificate has expired"
    } else {
      set status [catch {exec openssl x509 -in "$CERT" -noout -checkend 604800 > /dev/null 2>&1} output]
      if {$status == 1} {
        set MSG "Your certificate is going to expire in less than one week"
      }
    }
  } else {
    set MSG "Cannot find certificate file $CERT"
  }
}
# COLORS with tcl escaped [
set Cm "\033\[35m"
set Cy "\033\[33m"
set Cc "\033\[36m"
set Cb "\033\[34m"
set Cg "\033\[32m"
set Cr "\033\[31m"
set Cw "\033\[37m"
set Cz "\033\[0m"
set Br "\033\[41m"
set By "\033\[43m"
if { [info exists MSG] && $MSG ne ""} {
  puts stderr "${MSG}"
}
if { [info exists MSG] && $MSG ne ""} {
  puts stderr "${Br}${Cw}!!! ${MSG} !!!${Cz}"
}
EoF
