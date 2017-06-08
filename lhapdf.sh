package: lhapdf
version: "%(tag_basename)s%(defaults_upper)s"
tag: v6.1.6
source: https://github.com/alisw/LHAPDF
requires:
 - yaml-cpp
 - boost
 - "Python-modules:slc[567]"
build_requires:
 - autotools
 - "Python-system:(?!slc[567])"
env:
  LHAPATH: "$LHAPDF_ROOT/share/LHAPDF"
---
#!/bin/bash -ex
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $YAML_CPP_ROOT ]] && YAML_CPP_ROOT=`brew --prefix yaml-cpp`
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $AUTOTOOLS_ROOT ]] && PATH=$PATH:`brew --prefix gettext`/bin
  ;;
  *)
    EXTRA_LD_FLAGS="-Wl,--no-as-needed"
  ;;
esac

rsync -a --exclude '**/.git' $SOURCEDIR/ ./

case $PKGVERSION in
  v6.0*) WITH_YAML_CPP="--with-yaml-cpp=${YAML_CPP_ROOT}"
esac

if [[ "$BOOST_ROOT" != '' ]]; then
  export LDFLAGS="$EXTRA_LD_FLAGS -L${BOOST_ROOT}/lib"
  export CXXFLAGS="-I${BOOST_ROOT}/include"
fi
export LIBRARY_PATH="$LD_LIBRARY_PATH"

autoreconf -ivf
./configure --prefix=$INSTALLROOT \
            ${BOOST_ROOT:+--with-boost="$BOOST_ROOT"} \
            $WITH_YAML_CPP

make ${JOBS+-j $JOBS} all
make install

PDFSETS="cteq6l1 MMHT2014lo68cl MMHT2014nlo68cl"
$INSTALLROOT/bin/lhapdf install $PDFSETS
# Check if PDF sets were really installed
for P in $PDFSETS; do
  ls $INSTALLROOT/share/LHAPDF/$P
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
module load BASE/1.0 ${YAML_CPP_VERSION:+yaml-cpp/$YAML_CPP_VERSION-$YAML_CPP_REVISION} ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
setenv LHAPDF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LHAPATH \$::env(LHAPDF_ROOT)/share/LHAPDF
prepend-path PATH $::env(LHAPDF_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(LHAPDF_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(LHAPDF_ROOT)/lib")
EoF
