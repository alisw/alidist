package: Python-modules-ROOT
version: "1.0"
requires:
  - "Python:slc.*"
  - "Python-system:(?!slc.*)"
  - FreeType
  - libpng
  - Python-modules
  - ROOT
build_requires:
  - curl
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/lib/python/site-packages
---
#!/bin/bash -ex

# Major.minor version of Python
export PYVER=$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')

# Ignore what is already in PYTHONPATH. We will set PYTHONPATH or PYTHONUSERBASE per command
unset PYTHONPATH

# *** IMPORTANT NOTE FOR CONTRIBUTORS ***
# In order to ensure reproducibility (i.e. if we rebuild this same package over time we want to get
# the exact same result) we absolutely need to specify the exact versions of the desired packages.
# In order to get the exact versions, you can use `pip freeze` on your local installation.
PIP_REQUIREMENTS=(
  # pack==version           import_module
  "scikit-hep==0.5.1        scikit-hep"
  "root_numpy==4.8.0        root_numpy"
  "root_pandas==0.7.0       root_pandas"
  )

# Install pip packages under a user folder, but unset it right after installation
for P in "${PIP_REQUIREMENTS[@]}"; do
  echo $P | cut -d' ' -f1
done > requirements.txt

env PYTHONUSERBASE="$INSTALLROOT" pip3 install --user -IU -r requirements.txt

# Find the proper Python lib library and export it
pushd "$INSTALLROOT"
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
    sed -i.deleteme -e "1 s|^#!${INSTALLROOT}/bin/\(.*\)$|#!/usr/bin/env \1|" * || true
    rm -f *.deleteme || true
  popd
popd

# Patch long shebangs (by default max is 128 chars on Linux)
pushd "$INSTALLROOT/bin"
  sed -i.deleteme -e '1 s|^#!.*$|#!/usr/bin/env python3|' * || true
  rm -f *.deleteme
popd

# Remove useless stuff
rm -rvf "$INSTALLROOT"/share "$INSTALLROOT"/lib/python*/test
find "$INSTALLROOT"/lib/python* \
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
module load BASE/1.0 ${PYTHON_MODULES_VERSION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION} ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
set PYTHON_MODULES_ROOT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHON_MODULES_ROOT_ROOT/bin
prepend-path LD_LIBRARY_PATH \$PYTHON_MODULES_ROOT_ROOT/lib
prepend-path PYTHONPATH \$PYTHON_MODULES_ROOT_ROOT/lib/python/site-packages
EoF
