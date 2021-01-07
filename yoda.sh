package: YODA
version: "%(tag_basename)s"
tag: "v1.8.2"
source: https://github.com/alisw/yoda
requires:
  - boost
  - "Python:slc.*"
  - "Python-system:(?!slc.*)"
build_requires:
  - "autotools:(slc6|slc7)"
prepend_path:
  PYTHONPATH: $YODA_ROOT/lib64/python2.7/site-packages:$YODA_ROOT/lib/python2.7/site-packages
---
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

[[ -e .missing_timestamps ]] && ./missing-timestamps.sh --apply || autoreconf -ivf

(
unset PYTHON_VERSION
./configure --prefix="$INSTALLROOT"
make -j$JOBS
make install
)

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
module load BASE/1.0                                                    \\
            boost/$BOOST_VERSION-$BOOST_REVISION                        \\
            ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}

# Our environment
set YODA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version

prepend-path PATH \$YODA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib64
set pythonpath [exec yoda-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
EoF
