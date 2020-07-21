package: Python-modules
version: "1.0"
requires:
  - "Python:slc.*"
  - "Python-system:(?!slc.*)"
  - FreeType
  - libpng
build_requires:
  - curl
  - Python-modules-list
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/share/python-modules/lib/python/site-packages
---
#!/bin/bash -ex

# Major.minor version of Python
export PYVER=$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')

# Ignore what is already in PYTHONPATH. We will set PYTHONPATH or PYTHONUSERBASE per command
unset PYTHONPATH

# PIP_REQUIREMENTS & PIP36_REQUIREMENTS come from Python-modules-list
echo $PIP_REQUIREMENTS | tr \  \\n > requirements.txt
if python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3006 else 1)' && [[ $ARCHITECTURE != slc6* ]]; then
  echo $PIP36_REQUIREMENTS | tr \  \\n >> requirements.txt
fi

# We use a different INSTALLROOT, so that we can build updatable RPMS which
# do not conflict with the underlying Python installation.
PYTHON_MODULES_INSTALLROOT=$INSTALLROOT/share/python-modules
mkdir -p $PYTHON_MODULES_INSTALLROOT
# Install setuptools upfront, since this seems to create issues now...
env PYTHONUSERBASE="$PYTHON_MODULES_INSTALLROOT" pip3 install --user -IU setuptools
# FIXME: required because of the newly introduced dependency on scikit-garden requires
# a numpy to be installed separately
# See also:
#   https://github.com/scikit-garden/scikit-garden/issues/23
grep RootInteractive requirements.txt && env PYTHONUSERBASE="$PYTHON_MODULES_INSTALLROOT" pip3 install --user -IU numpy
# Do not move cython from 0.29.06 for now since 3.0.0rc1 breaks on GPU
grep RootInteractive requirements.txt && env PYTHONUSERBASE="$PYTHON_MODULES_INSTALLROOT" pip3 install --user -IU cython==0.29.16
env PYTHONUSERBASE="$PYTHON_MODULES_INSTALLROOT" pip3 install --user -IU -r requirements.txt

# Find the proper Python lib library and export it
pushd "$PYTHON_MODULES_INSTALLROOT"
  if [[ -d lib64 ]]; then
    ln -nfs lib64 lib  # creates lib pointing to lib64
  elif [[ -d lib ]]; then
       ln -nfs lib lib64 # creates lib64 pointing to lib
  fi
  pushd lib
    ln -nfs python$PYVER python
  popd
  pushd bin
    # Fix shebangs: remove hardcoded Python path
    sed -i.deleteme -e "1 s|^#!${PYTHON_MODULES_INSTALLROOT}/bin/\(.*\)$|#!/usr/bin/env \1|" * || true
    rm -f *.deleteme || true
  popd
popd

# Patch long shebangs (by default max is 128 chars on Linux)
pushd "$PYTHON_MODULES_INSTALLROOT/bin"
  sed -i.deleteme -e '1 s|^#!.*$|#!/usr/bin/env python3|' * || true
  rm -f *.deleteme
popd

# Remove useless stuff
rm -rvf "$PYTHON_MODULES_INSTALLROOT"/share "$PYTHON_MODULES_INSTALLROOT"/lib/python*/test
find "$PYTHON_MODULES_INSTALLROOT"/lib/python* \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}' \;

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
module load BASE/1.0 ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION} ${ALIEN_RUNTIME_REVISION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}
# Our environment
set PYTHON_MODULES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHON_MODULES_ROOT/share/python-modules/bin
prepend-path LD_LIBRARY_PATH \$PYTHON_MODULES_ROOT/share/python-modules/lib
prepend-path PYTHONPATH \$PYTHON_MODULES_ROOT/share/python-modules/lib/python/site-packages
EoF
