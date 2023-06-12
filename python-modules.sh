package: Python-modules
version: "1.0"
requires:
  - "Python:(slc|ubuntu)"
  - "Python-system:(?!slc.*|ubuntu)"
  - "FreeType:(?!osx)"
  - libpng
build_requires:
  - curl
  - Python-modules-list
  - alibuild-recipe-tools
prepend_path:
  PATH: "$PYTHON_MODULES_ROOT/share/python-modules/bin"
  LD_LIBRARY_PATH: "$PYTHON_MODULES_ROOT/share/python-modules/lib"
  # If we need tensorflow to work on Mac, we must use lib/python$pyver, not lib/python here.
  PYTHONPATH: $PYTHON_MODULES_ROOT/share/python-modules/lib/python/site-packages
---
#!/bin/bash -e
if [ -n "$VIRTUAL_ENV" ]; then
  # Once more to get the deactivate
  . "$VIRTUAL_ENV/bin/activate"
  deactivate
fi
# A spurious PYTHONPATH can affect later commands
unset PYTHONPATH

# We use a different INSTALLROOT, so that we can build updatable RPMS which
# do not conflict with the underlying Python installation.
PYTHON_MODULES_INSTALLROOT=$INSTALLROOT/share/python-modules

case $ARCHITECTURE in
  osx_arm64)
    # On ARM Macs, we need to install Conda to get Tensorflow with hardware support.
    # Available version list: https://repo.anaconda.com/miniconda/
    # The Python version of this Conda env matters! Keep it in sync
    # with the "PIPXY_REQUIREMENTS_osx_arm64" clause in Python-modules-list.
    curl -fsSLo miniconda.sh 'https://repo.anaconda.com/miniconda/Miniconda3-py39_23.3.1-0-MacOSX-arm64.sh'
    bash miniconda.sh -b -p "$PYTHON_MODULES_INSTALLROOT"
    . "$PYTHON_MODULES_INSTALLROOT/bin/activate"
    conda install -y -c apple tensorflow-deps ;;
  *)
    # On other platforms, just create a plain virtualenv.
    python3 -m venv "$PYTHON_MODULES_INSTALLROOT"
    . "$PYTHON_MODULES_INSTALLROOT/bin/activate" ;;
esac

# Major.minor version of Python
pyver="$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')"

# These are the basic requirements needed for all installation and platform
# and it should represent the common denominator (working) for all packages/platforms
echo "$PIP_BASE_REQUIREMENTS" | tr '[:space:]' '\n' > base-requirements.txt

# PIP*_REQUIREMENTS variables come from python-modules-list.sh.
case $ARCHITECTURE in
  slc6_*) echo "$PIP_REQUIREMENTS" ;;
  *)
    echo "$PIP_REQUIREMENTS"
    # Handle special lists for different platforms, e.g. $PIP39_REQUIREMENTS_osx_arm64.
    this_pyver_requirements_var=PIP${pyver/.}_REQUIREMENTS
    this_pyver_arch_requirements_var=PIP${pyver/.}_REQUIREMENTS_${ARCHITECTURE//-/_}
    # Use $PIPxy_REQUIREMENTS_arch if set, falling back to $PIPxy_REQUIREMENTS.
    echo "${!this_pyver_arch_requirements_var:-${!this_pyver_requirements_var}}" ;;
esac | tr -s '[:space:]' '\n' > requirements.txt

# Install pinned basic requirements for python infrastructure
python3 -m pip install -IU -r base-requirements.txt

# FIXME: required because of the newly introduced dependency on scikit-garden requires
# a numpy to be installed separately
# See also:
#   https://github.com/scikit-garden/scikit-garden/issues/23
python3 -m pip install -IU numpy
python3 -m pip install -IU -r requirements.txt

# Find the proper Python lib library and export it
pushd "$PYTHON_MODULES_INSTALLROOT"
  # let's remove any pre-existent symlinks to have a clean slate
  [ -h lib64 ] && unlink lib64
  [ -h lib ]   && unlink lib
  if [[ -d lib64 ]]; then
    ln -nfs lib64 lib  # creates lib pointing to lib64
  elif [[ -d lib ]]; then
    ln -nfs lib lib64  # creates lib64 pointing to lib
  fi
  ln -nfs "python$pyver" lib/python
popd

# Remove useless stuff
rm -rvf "$PYTHON_MODULES_INSTALLROOT"/share "$PYTHON_MODULES_INSTALLROOT"/lib/python*/test
find "$PYTHON_MODULES_INSTALLROOT"/lib/python* \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}' \;

case $ARCHITECTURE in
  osx_arm64) ;;
  *)
    # Fix shebangs: remove hardcoded Python path
    find "$PYTHON_MODULES_INSTALLROOT/bin" -type f -exec sed -i.deleteme -e "s|${PYTHON_MODULES_INSTALLROOT}|/usr|;s|python3|env python3|" '{}' \;
    find "$PYTHON_MODULES_INSTALLROOT/bin" -name '*.deleteme' -delete ;;
esac

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEDIR/$PKGNAME"
cat >> "$MODULEDIR/$PKGNAME" <<EoF
# Our environment
set PYTHON_MODULES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PYTHON_MODULES_ROOT/share/python-modules/bin
prepend-path LD_LIBRARY_PATH \$PYTHON_MODULES_ROOT/share/python-modules/lib
# We need to use lib/python$pyver, not lib/python here so that tensorflow-metal works on Mac.
prepend-path PYTHONPATH \$PYTHON_MODULES_ROOT/share/python-modules/lib/python$pyver/site-packages
EoF
