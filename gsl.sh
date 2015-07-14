package: GSL
version: "1.16"
---
#!/bin/bash -e
Url="ftp://ftp.gnu.org/gnu/gsl/gsl-${PKGVERSION}.tar.gz"
curl -o gsl.tar.gz "$Url"
tar xzf gsl.tar.gz
cd gsl-$PKGVERSION
./configure --prefix="$INSTALLROOT"
make -j$JOBS
make install -j$JOBS

# Modulefile
ModuleDir="${INSTALLROOT}/etc/Modules/modulefiles/${PKGNAME}"
mkdir -p "$ModuleDir"
cat > "${ModuleDir}/${PKGVERSION}-${PKGREVISION}" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "Module for loading $PKGNAME $PKGVERSION-$PKGREVISION for the ALICE environment"
}
set version $PKGVERSION-$PKGREVISION
module-whatis "Module for loading $PKGNAME $PKGVERSION-$PKGREVISION for the ALICE environment"
# Dependencies
module load BASE/1.0
# Our environment
if { [info exists ::env(OVERRIDE_BASE)] && \$::env(OVERRIDE_BASE) == 1 } then {
  puts stderr "Note: overriding base package $PKGNAME \$version"
  set prefix \$ModulesCurrentModulefile
  for {set i 0} {\$i < 5} {incr i} {
    set prefix [file dirname \$prefix]
  }
  setenv GSL_BASEDIR \$prefix
} else {
  setenv GSL_BASEDIR \$::env(BASEDIR)/$PKGNAME/\$version
}
prepend-path LD_LIBRARY_PATH \$::env(GSL_BASEDIR)/lib
prepend-path PATH \$::env(GSL_BASEDIR)/bin
EoF
