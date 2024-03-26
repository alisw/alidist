package: pythia
version: "%(tag_basename)s"
tag: v8311
source: https://github.com/alisw/pythia8
requires:
  - lhapdf
  - HepMC
  - boost
env:
  PYTHIA8DATA: "$PYTHIA_ROOT/share/Pythia8/xmldoc"
  PYTHIA8: "$PYTHIA_ROOT"
---
#!/bin/bash -e
rsync -a $SOURCEDIR/ ./
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
esac

./configure --prefix=$INSTALLROOT \
            --enable-shared \
            ${HEPMC_ROOT:+--with-hepmc2="$HEPMC_ROOT"} \
            ${LHAPDF_ROOT:+--with-lhapdf6="$LHAPDF_ROOT"} \
            ${BOOST_ROOT:+--with-boost="$BOOST_ROOT"}

if [[ $ARCHITECTURE =~ "slc5.*" ]]; then
    ln -s LHAPDF5.h include/Pythia8Plugins/LHAPDF5.cc
    ln -s LHAPDF6.h include/Pythia8Plugins/LHAPDF6.cc
    sed -i -e 's#\$(CXX) -x c++ \$< -o \$@ -c -MD -w -I\$(LHAPDF\$\*_INCLUDE) \$(CXX_COMMON)#\$(CXX) -x c++ \$(<:.h=.cc) -o \$@ -c -MD -w -I\$(LHAPDF\$\*_INCLUDE) \$(CXX_COMMON)#' Makefile
fi

make ${JOBS+-j $JOBS}
make install
chmod a+x $INSTALLROOT/bin/pythia8-config

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
module load BASE/1.0 ${LHAPDF_REVISION:+lhapdf/$LHAPDF_VERSION-$LHAPDF_REVISION} ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${HEPMC_REVISION:+HepMC/$HEPMC_VERSION-$HEPMC_REVISION}
# Our environment
set PYTHIA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PYTHIA_ROOT \$PYTHIA_ROOT
setenv PYTHIA8DATA \$PYTHIA_ROOT/share/Pythia8/xmldoc
setenv PYTHIA8 \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHIA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$PYTHIA_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$PYTHIA_ROOT/include
EoF
