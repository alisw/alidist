package: lhapdf
version: "%(tag_basename)s"
tag: v6.5.2
source: https://github.com/alisw/LHAPDF
requires:
  - "Python"
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - "autotools:(slc6|slc7)"
prepend_path:
  PYTHONPATH: $LHAPDF_ROOT/lib/python/site-packages
---
#!/bin/bash -ex
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $AUTOTOOLS_ROOT ]] && PATH=$PATH:`brew --prefix gettext`/bin
    # Do not compile Python2 bindings on Mac
    DISABLE_PYTHON=1
  ;;
  *)
    EXTRA_LD_FLAGS="-Wl,--no-as-needed"
  ;;
esac

rsync -a --exclude '**/.git' $SOURCEDIR/ ./

export LIBRARY_PATH="$LD_LIBRARY_PATH"

if type "python" &>/dev/null; then
  # Python2 or Python3 point to "python"
  if python -c 'import sys; exit(0 if sys.version_info.major >=3 else 1)'; then
    # LHAPDF not yet ready for Python3
    DISABLE_PYTHON=1
  fi
else
  # Python2 not installed and Python3 points to "python3"
  DISABLE_PYTHON=1
fi

autoreconf -ivf
./configure --prefix=$INSTALLROOT ${DISABLE_PYTHON:+--disable-python}

make ${JOBS+-j $JOBS} all
make install

pushd "$INSTALLROOT"
  # Fix ambiguity between lib/lib64
  if [[ ! -d lib && -d lib64 ]]; then
    ln -nfs lib64 lib
  elif [[ -d lib && ! -d lib64 ]]; then
    ln -nfs lib lib64
  fi
  # Uniform Python library path
  pushd lib
    ln -nfs python* python
  popd
popd

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
                     ${PYTHON_MODULES_ROOT:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION} 
# Our environment
set LHAPDF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LHAPDF_ROOT \$LHAPDF_ROOT
prepend-path PATH \$LHAPDF_ROOT/bin
prepend-path LD_LIBRARY_PATH \$LHAPDF_ROOT/lib
prepend-path PYTHONPATH \$LHAPDF_ROOT/lib/python/site-packages
prepend-path LHAPDF_DATA_PATH \$LHAPDF_ROOT/share/LHAPDF
EoF
