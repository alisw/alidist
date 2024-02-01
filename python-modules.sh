package: Python-modules
version: "1.0"
requires:
  - "Python:(slc|ubuntu)"
  - "Python-system:(?!slc.*|ubuntu)"
  - "FreeType:(?!osx)"
  - libpng
build_requires:
  - Python-modules-list
  - alibuild-recipe-tools
prepend_path:
  PATH: "$PYTHON_MODULES_ROOT/share/python-modules/bin"
  LD_LIBRARY_PATH: "$PYTHON_MODULES_ROOT/share/python-modules/lib"
  PYTHONPATH: "$PYTHON_MODULES_ROOT/share/python-modules"
---
#!/bin/bash -e
unset VIRTUAL_ENV

# We use a different INSTALLROOT, so that we can build updatable RPMS which
# do not conflict with the underlying Python installation.
PYTHON_MODULES_INSTALLROOT=$INSTALLROOT/share/python-modules
export PYTHONPATH="$PYTHON_MODULES_INSTALLROOT:${PYTHONPATH:+:$PYTHONPATH}"

# Install pinned basic requirements for python infrastructure
echo "$PIP_BASE_REQUIREMENTS" > base-requirements.txt
python3 -m pip install -IU -t "$PYTHON_MODULES_INSTALLROOT" -r base-requirements.txt
# The above updates pip and setuptools, so install the rest of the packages separately.
echo "$PIP_REQUIREMENTS" > requirements.txt
python3 -m pip install -IU -t "$PYTHON_MODULES_INSTALLROOT" -r requirements.txt

# Remove useless stuff
rm -rvf "$PYTHON_MODULES_INSTALLROOT/share"
find "$PYTHON_MODULES_INSTALLROOT" -mindepth 2 -maxdepth 2 \
     -type d -and \( -name test -or -name tests \) -exec rm -rvf '{}' \;

# Fix shebangs: remove hardcoded Python path
find "$PYTHON_MODULES_INSTALLROOT/bin" -type f -exec sed -i.deleteme -e "s|${PYTHON_MODULES_INSTALLROOT}|/usr|;s|python3|env python3|" '{}' \;
find "$PYTHON_MODULES_INSTALLROOT/bin" -name '*.deleteme' -delete

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
cat >> "$INSTALLROOT/etc/modulefiles/$PKGNAME" <<EOF
# Binaries are installed into non-standard paths.
set PKG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$PKG_ROOT/share/python-modules/bin
prepend-path LD_LIBRARY_PATH \$PKG_ROOT/share/python-modules/lib
prepend-path PYTHONPATH \$PKG_ROOT/share/python-modules
EOF
