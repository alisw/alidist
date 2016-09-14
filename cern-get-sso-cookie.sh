package: cern-get-sso-cookie
version: "1.0"
source: https://github.com/ktf/cern-get-sso-cookie
prefer_system: .*
prefer_system_check: which cern-get-sso-cookie
---
#!/bin/bash -ex

curl http://cpanmin.us | perl - -l $INSTALLROOT local::lib Authen::Krb5 WWW::Curl::Easy
mkdir -p $INSTALLROOT/bin $INSTALLROOT/lib/perl5/WWW/CERNSSO
cp $SOURCEDIR/cern-get-sso-cookie/usr/share/perl5/WWW/CERNSSO/Auth.pm $INSTALLROOT/lib/perl5/WWW/CERNSSO/Auth.pm
cp $SOURCEDIR/cern-get-sso-cookie/usr/bin/cern-get-sso-cookie $INSTALLROOT/bin

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
setenv PERL_MODULES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(PERL_MODULES_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(PERL_MODULES_ROOT)/lib
prepend-path PERL5LIB $::env(PERL_MODULES_ROOT)/lib/perl5
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(PERL_MODULES_ROOT)/lib")
EoF
