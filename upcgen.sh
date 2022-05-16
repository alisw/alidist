package: Upcgen
version: "%(tag_basename)s"
tag: tag-15-05-22-3
source: https://github.com/alisw/upcgen
requires:
  - ROOT
  - HepMC3
  - pythia
build_requires:
  - CMake
  - GCC-Toolchain:(?!osx.*)
---
#!/bin/bash -e

cmake $SOURCEDIR                          \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DBUILD_WITH_HEPMC=ON               \
      -DBUILD_WITH_OPENMP=ON              \
      -DBUILD_WITH_PYTHIA6=OFF            \
      -DBUILD_WITH_PYTHIA8=ON

cmake --build . -- ${JOBS:+-j$JOBS}
mkdir -p $INSTALLROOT/bin
cp ./upcgen $INSTALLROOT/bin/
mkdir -p $INSTALLROOT/lib
cp ./libUpcgenlib.a $INSTALLROOT/lib/.
cp -r $SOURCEDIR/include $INSTALLROOT/.

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF

# Our environment
set UPCGEN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv UPCGEN_ROOT \$UPCGEN_ROOT
prepend-path PATH \$UPCGEN_ROOT/bin
prepend-path LD_LIBRARY_PATH \$UPCGEN_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
