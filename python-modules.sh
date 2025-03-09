package: Python-modules
version: "1.0"
requires:
  - "Python"
  - "FreeType:(?!osx)"
  - libpng
  - hdf5
build_requires:
  - Python-modules-list
  - alibuild-recipe-tools
prepend_path:
  # If we need tensorflow-metal to work on Mac during subsequent builds, we
  # must use lib/python$pyver, not lib/python here.
  PYTHONPATH: "$PYTHON_MODULES_ROOT/lib/python/site-packages"
prefer_system: ".*"
prefer_system_check: |
  # if we are in a virtualenv, assume people know what they are doing
  # and simply use the virtualenv recipe.
  if [ -n "$VIRTUAL_ENV" ]; then
    echo "alibuild_system_replace: virtualenv"
    exit 0
  fi
  # If not, either they are using the system python or they are using our own python.
  # In both cases we can simply create our own virtualenv
  exit 1
prefer_system_replacement_specs:
  virtualenv:
    version: "virtualenv"
    recipe: |
      # Install pinned basic requirements for python infrastructure
      echo "$PIP_BASE_REQUIREMENTS" > base-requirements.txt
      python3 -m pip install -IU -r base-requirements.txt
      # The above updates pip and setuptools, so install the rest of the packages separately.
      echo "$PIP_REQUIREMENTS" > requirements.txt
      python3 -m pip install -IU -r requirements.txt
      # We do not need anything else, because python is going to be in path
      # if we are inside a virtualenv so no need to pretend we know where
      # the correct python is.

      # We generate the modulefile to avoid complains by dependencies
      mkdir -p "$INSTALLROOT/etc/modulefiles"
      alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
    requires:
      - "FreeType:(?!osx)"
      - libpng
      - hdf5
    build_requires:
      - Python-modules-list
      - alibuild-recipe-tools
---
#!/bin/bash -e
# Users might want to install more packages in the same environment. A venv
# provides a pip binary that will install packages into the same path.
# This copies the system python binary (or the one from PYTHON_ROOT) into the
# venv. We must not use symlinks, since those break if the package is uploaded
# to a remote store.
# NOTE: If you get an error saying "Error: This build of python cannot create
# venvs without using symlinks", then you are using the MacOS Python. You
# should be using the Homebrew Python instead, so run "brew install python".
python3 -m venv --copies "$INSTALLROOT"
. "$INSTALLROOT/bin/activate"
# From now on, we use the python3 binary copied into the venv. This makes pip
# install packages into the venv.

# Major.minor version of Python, needed for PYTHONPATH.
pyver="$(python3 -c 'import sys; print(str(sys.version_info[0]) + "." + str(sys.version_info[1]))')"

# Install pinned basic requirements for python infrastructure
echo "$PIP_BASE_REQUIREMENTS" > base-requirements.txt
python3 -m pip install -IU -r base-requirements.txt
# The above updates pip and setuptools, so install the rest of the packages separately.
echo "$PIP_REQUIREMENTS" > requirements.txt
python3 -m pip install -IU -r requirements.txt

# Remove useless stuff
rm -rvf "$INSTALLROOT/share"
find "$INSTALLROOT" -mindepth 2 -maxdepth 2 \
     -type d -and \( -name test -or -name tests \) -exec rm -rvf '{}' \;

# Fix shebangs: remove hardcoded Python path. Scripts' shebangs will point at
# the venv's python using an absolute path by default, which we must change.
find "$INSTALLROOT"/bin -type f -exec sed -r -i.deleteme -e "1s,^#!$INSTALLROOT/bin/,#!/usr/bin/env ," {} \;
rm -f "$INSTALLROOT"/bin/*.deleteme

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
cat >> "$INSTALLROOT/etc/modulefiles/$PKGNAME" <<EOF
# We need to use lib/python$pyver, not lib/python here so that tensorflow-metal works on Mac.
prepend-path PYTHONPATH \$PKG_ROOT/lib/python$pyver/site-packages
EOF
