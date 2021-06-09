package: EVTGEN
version: "%(tag_basename)s"
tag: "R01-06-00"
source: https://github.com/PMunkes/evtgen.git
requires:
  - HepMC
  - pythia
  - TAUOLA
  - PHOTOS
build_requires:
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
env:
   EVTGENDATA: "$EVTGEN_ROOT/share"
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./

# adjust the configure scripts
sed -i -e "s/FLIBS=.*$/FLIBS=\"-lgfortran\"/" configure
sed -i -e "s/PYTHIALIBLIST=.*$/PYTHIALIBLIST=\"-lpythia8 -lpythia8lhapdf6\"/" configure

export HEPMCLOCATION="$HEPMC_ROOT"
./configure --prefix=$INSTALLROOT \
	    --hepmcdir=$HEPMC_ROOT \
	    --pythiadir=$PYTHIA_ROOT \
	    --tauoladir=$TAUOLA_ROOT \
	    --photosdir=$PHOTOS_ROOT 
make
make install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF

# Our environment
set EVTGEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv EVTGEN_ROOT \$EVTGEN_ROOT
prepend-path PATH \$EVTGEN_ROOT/bin
prepend-path LD_LIBRARY_PATH \$EVTGEN_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
