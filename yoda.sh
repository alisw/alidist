package: YODA
version: "%(tag_basename)s"
tag: "yoda-2.1.0"
source: https://gitlab.com/hepcedar/yoda.git
requires:
  - Python
  - Python-modules
  - ROOT
  - hdf5
build_requires:
  - "autotools:(slc6|slc7)"
  - HepMC3
  - Python
prepend_path:
  PYTHONPATH: $YODA_ROOT/lib/python/site-packages
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/ ./

[[ -e .missing_timestamps ]] && ./missing-timestamps.sh --apply || autoreconf -ivf

export PYTHON=$(type -p python3)

./configure --disable-silent-rules --enable-root --prefix="$INSTALLROOT"
make ${JOBS+-j $JOBS}
make install

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
module load BASE/1.0					\\
            ${PYTHON_FULL_VERSION:+Python/$PYTHON_FULL_VERSION}	\\
            ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}

# Our environment
set YODA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
 
prepend-path PATH \$YODA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib64
set pythonpath [exec \$YODA_ROOT/bin/yoda-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
prepend-path PYTHONPATH \$YODA_ROOT/lib/python/site-packages
EoF
