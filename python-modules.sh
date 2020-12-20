package: Python-modules
version: "1.0"
requires:
  - "Python:slc.*"
  - "Python-system:(?!slc.*)"
  - FreeType
  - libpng
build_requires:
  - system-curl
  - Python-modules-list
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/share/python-modules/lib/python/site-packages
---

# A spurios PYTHONPATH can affect later commands
unset PYTHONPATH
# If we are in a virtualenv, assume that what you want to do is to copy
# the same installation in your alibuild one.
if [ ! "X$VIRTUAL_ENV" = X ]; then
  # Once more to get the deactivate
  . $VIRTUAL_ENV/bin/activate
  pip freeze > system-requirements.txt
  deactivate
fi

# PIP_REQUIREMENTS, PIP36_REQUIREMENTS, PIP38_REQUIREMENTS come from python-modules-list.sh
echo $PIP_REQUIREMENTS | tr \  \\n > requirements.txt
case $ARCHITECTURE in
  slc6*);;
  *)
  if python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3009 else 1)'; then
    echo $PIP39_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3008 else 1)'; then
    echo $PIP38_REQUIREMENTS | tr \  \\n >> requirements.txt
  elif python3 -c 'import sys; exit(0 if 1000*sys.version_info.major + sys.version_info.minor >= 3006 else 1)'; then
    echo $PIP36_REQUIREMENTS | tr \  \\n >> requirements.txt
  fi
  ;;
esac
# We use a different INSTALLROOT, so that we can build updatable RPMS which
# do not conflict with the underlying Python installation.
PYTHON_MODULES_INSTALLROOT=$INSTALLROOT/share/python-modules
mkdir -p $PYTHON_MODULES_INSTALLROOT

# Create the virtualenv
python3 -m venv $PYTHON_MODULES_INSTALLROOT
. $PYTHON_MODULES_INSTALLROOT/bin/activate

# Upgrade pip
python3 -m pip install -IU pip
# Install setuptools upfront, since this seems to create issues now...
python3 -m pip install -IU setuptools
python3 -m pip install -IU wheel

# FIXME: required because of the newly introduced dependency on scikit-garden requires
# a numpy to be installed separately
# See also:
#   https://github.com/scikit-garden/scikit-garden/issues/23
python3 -m pip install -IU numpy
python3 -m pip install -IU -r requirements.txt

# Major.minor version of Python
export PYVER="$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')"
# Find the proper Python lib library and export it
pushd "$PYTHON_MODULES_INSTALLROOT"
  # let's remove any pre-existent symlinks to have a clean slate
  [ -h lib64 ] && unlink lib64
  [ -h lib ]   && unlink lib
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
    find . -type f -exec sed -i.deleteme -e "s|${PYTHON_MODULES_INSTALLROOT}|/usr|;s|python3|env python3|" '{}' \;
    find . -name "*.deleteme" -delete
  popd
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
