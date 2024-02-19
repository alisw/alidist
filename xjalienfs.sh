package: xjalienfs
version: "%(tag_basename)s"
tag: "1.5.9"
source: https://gitlab.cern.ch/jalien/xjalienfs.git
requires:
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - XRootD
  - AliEn-Runtime
  - Python-modules
build_requires:
  - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: ${XJALIENFS_ROOT}/lib/python/site-packages
---
#!/bin/bash -e

# Use pip's --target to install under $INSTALLROOT without weird hacks. This
# works inside and outside a virtualenv, but unset VIRTUAL_ENV to make sure we
# only depend on stuff we installed using our Python and Python-modules.
env -u VIRTUAL_ENV ALIBUILD=1 \
    python3 -m pip install --force-reinstall \
    --target="$INSTALLROOT/lib/python/site-packages" \
    "file://$SOURCEDIR"

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

# Now that alien.py is installed, we can run its tests.
set +x   # avoid echoing tokens
# Make sure we don't accidentally run read-write tests with users' JAliEn keys.
if [ -n "$ALIBUILD_XJALIENFS_TESTS" ] &&
     # Tests need a JAliEn token, so skip them if we have none.
     [ -n "$JALIEN_TOKEN_CERT" ] && [ -n "$JALIEN_TOKEN_KEY" ]
then
  PATH="$INSTALLROOT/bin:$PATH" \
  PYTHONPATH="$INSTALLROOT/lib/python/site-packages:$PYTHONPATH" \
  "$SOURCEDIR/tests/run_tests" ci-tests
fi
set -x

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
cat <<\EOF >> "$INSTALLROOT/etc/modulefiles/$PKGNAME"
prepend-path PYTHONPATH $PKG_ROOT/lib/python/site-packages
EOF
