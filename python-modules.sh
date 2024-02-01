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
  PYTHONPATH: "$PYTHON_MODULES_ROOT/lib/python/site-packages"
---
#!/bin/bash -e
unset VIRTUAL_ENV

# Install Python packages in a semi-standard location.
PYTHON_MODULES_INSTALLROOT=$INSTALLROOT/lib/python/site-packages
# Make sure we pick up the pip we install through base-requirements.txt directly.
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

# By default, "pip install --target" installs binaries inside the given target
# dir as well, but we want them directly under $INSTALLROOT/bin instead.
rm -rf "${INSTALLROOT:?}/bin"
mv "$PYTHON_MODULES_INSTALLROOT/bin" "$INSTALLROOT/bin"

# Fix shebangs: remove hardcoded Python path. Most scripts will have a shebang
# like "#!<PYTHON_ROOT>/bin/python3" by default, which we must change.
sed -r -i.deleteme -e "1s,^#!(${PYTHON_ROOT:+$PYTHON_ROOT|}$PYTHON_MODULES_INSTALLROOT)/bin/(.+),#!/usr/bin/env \2," \
    "$INSTALLROOT"/bin/*
rm -f "$INSTALLROOT"/bin/*.deleteme

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
cat >> "$INSTALLROOT/etc/modulefiles/$PKGNAME" <<EOF
prepend-path PYTHONPATH \$PKG_ROOT/lib/python/site-packages
EOF
