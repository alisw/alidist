package: YODA
version: "v1.4.0"
---
#!/bin/bash -e
VerWithoutV=${PKGVERSION:1}
Url="http://www.hepforge.org/archive/yoda/YODA-${VerWithoutV}.tar.bz2"

# TODO: deps from CVMFS must disappear
Boost="/cvmfs/alice.cern.ch/x86_64-2.6-gnu-4.1.2/Packages/boost/v1_53_0"

curl -Lo yoda.tar.bz2 "$Url"
tar xjf yoda.tar.bz2
cd YODA-$VerWithoutV
./configure --prefix="$INSTALLROOT" --with-boost="$Boost"
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
module load BASE/1.0 boost/v1_53_0
# Our environment
if { [info exists ::env(OVERRIDE_BASE)] && \$::env(OVERRIDE_BASE) == 1 } then {
  puts stderr "Note: overriding base package $PKGNAME \$version"
  set prefix \$ModulesCurrentModulefile
  for {set i 0} {\$i < 5} {incr i} {
    set prefix [file dirname \$prefix]
  }
  setenv YODA_BASEDIR \$prefix
} else {
  setenv YODA_BASEDIR \$::env(BASEDIR)/$PKGNAME/\$version
}
prepend-path LD_LIBRARY_PATH \$::env(YODA_BASEDIR)/lib
prepend-path PATH \$::env(YODA_BASEDIR)/bin
set pythonpath [exec yoda-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
EoF
