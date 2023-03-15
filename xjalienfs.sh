package: xjalienfs
version: "%(tag_basename)s"
tag: "1.4.5"
source: https://gitlab.cern.ch/jalien/xjalienfs.git
requires:
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - AliEn-CAs
  - XRootD
  - Python-modules:(?!osx_arm64)
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

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --bin > "etc/modulefiles/${PKGNAME}"

cat >> "etc/modulefiles/${PKGNAME}" <<EoF
setenv XJALIENFS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH $PKG_ROOT/lib/python/site-packages
EoF

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"
