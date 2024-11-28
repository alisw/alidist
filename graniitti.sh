package: Graniitti
version: v1.09
tag: master
requires:
  - ROOT
  - HepMC3
  - lhapdf
  - lhapdf-pdfsets
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
source: https://github.com/mieskolainen/graniitti
---
#!/bin/bash -e

# enable output to be created in local directory
sed -i '/FULL_OUTPUT_STR =/c\    FULL_OUTPUT_STR = OUTPUT + "." + FORMAT;' $SOURCEDIR/src/MGraniitti.cc

# prepare INSTALLDIR
cp $SOURCEDIR/Makefile $INSTALLROOT/.
ln -s $SOURCEDIR/src $INSTALLROOT/src
ln -s $SOURCEDIR/include $INSTALLROOT/include
ln -s $SOURCEDIR/libs $INSTALLROOT/libs
mkdir $INSTALLROOT/bin
mkdir -p $INSTALLROOT/obj/bin

# compile gr
export HEPMC3SYS=$HEPMC3_ROOT
export LHAPDFSYS=$LHAPDF_ROOT
make -C $INSTALLROOT ${JOBS+-j$JOBS} CXX_ROOT=c++2a

# clean INSTALLDIR
rm $INSTALLROOT/src $INSTALLROOT/include $INSTALLROOT/libs
cp -R $SOURCEDIR/modeldata $INSTALLROOT/.

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
# we define this so that the starlight installation can be found/queried
setenv ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
# we purposely are not adding to ROOT_INCLUDE_PATH
# to avoid making that search path to long. Users can do
# this themsevles in the ROOT macro (just-in-time) via ${PKGNAME}_ROOT.
# prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include/
EOF
