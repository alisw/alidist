package: PHOTOS
version: "%(tag_basename)s"
tag: "v.3.64"
source: https://github.com/ffionda/PHOTOS.git
requires:
  - HepMC
build_requires:
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./

autoreconf -ifv
./configure --prefix $INSTALLROOT --with-hepmc="$HEPMC_ROOT"
make -j$JOBS
make install

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME

cat << EOF >> $INSTALLROOT/etc/modulefiles/$PKGNAME
set PHOTOS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PHOTOS_ROOT \$PHOTOS_ROOT
setenv PHOTOS_INSTALL_PATH \$PHOTOS_ROOT/lib/PHOTOS
prepend-path PATH \$PHOTOS_ROOT/bin
prepend-path LD_LIBRARY_PATH \$PHOTOS_ROOT/lib
EOF
