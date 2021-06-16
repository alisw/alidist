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
  - alibuild-recipe-tools
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
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --extra > "$MODULEDIR/$PKGNAME" <<\EoF
prepend-path LD_LIBRARY_PATH $PKG_ROOT/lib64
set pythonpath [exec yoda-config --pythonpath]
prepend-path PYTHONPATH $pythonpath
EoF
