package: pytorch
version: "%(tag_basename)s"
tag: "2.2.1"
requires:
  - Python
  - Python-modules
build_requires:
  - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: "$PYTORCH_ROOT/lib/python/site-packages"
  # For C++ bindings.
  CMAKE_PREFIX_PATH: "$(python3 -c 'import torch; print(torch.utils.cmake_prefix_path)')"
---
#!/bin/bash -e

# Use pip's --target to install under $INSTALLROOT without weird hacks. This
# works inside and outside a virtualenv, but unset VIRTUAL_ENV to make sure we
# only depend on stuff we installed using our Python and Python-modules.
unset VIRTUAL_ENV
python3 -m pip install torch --force-reinstall \
        --target="$INSTALLROOT/lib/python/site-packages"

# Make sure all the tools use the correct python
# By default, pip install --target installs binaries inside the given target dir
# as well, but we want them directly under $INSTALLROOT/bin instead.
rm -rf "${INSTALLROOT:?}/bin"
mv "$INSTALLROOT/lib/python/site-packages/bin" "$INSTALLROOT/bin"
for binfile in "$INSTALLROOT"/bin/*; do
  [ -f "$binfile" ] || continue
  if grep -q "^'''exec' .*python.*" "$binfile"; then
    # This file uses a hack to get around shebang size limits. As we're
    # replacing the shebang with the system python, the limit doesn't apply and
    # we can just use a normal shebang.
    sed -i.bak '1d; 2d; 3d; 4s,^,#!/usr/bin/env python3\n,' "$binfile"
  else
    sed -i.bak '1s,^#!.*python.*,#!/usr/bin/env python3,' "$binfile"
  fi
done
rm -fv "$INSTALLROOT"/bin/*.bak

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
cat <<\EOF >> "$INSTALLROOT/etc/modulefiles/$PKGNAME"
prepend-path PYTHONPATH $PKG_ROOT/lib/python/site-packages
prepend-path CMAKE_PREFIX_PATH [exec python3 -c "import torch; print(torch.utils.cmake_prefix_path)"]
EOF
