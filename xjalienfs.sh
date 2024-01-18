package: xjalienfs
version: "%(tag_basename)s"
tag: "1.5.7"
source: https://gitlab.cern.ch/jalien/xjalienfs.git
requires:
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - XRootD
  - AliEn-Runtime
  - Python-modules
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
module load ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION}                                 \\
            ${PYTHON_MODULES_REVISION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION} \\
            ${ALIEN_RUNTIME_REVISION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}     \\
            ${OPENSSL_REVISION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}                             \\
	    ${XROOTD_REVISION:+XRootD/$XROOTD_VERSION-$XROOTD_REVISION}
set XJALIENFS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$XJALIENFS_ROOT/bin
prepend-path PYTHONPATH \$XJALIENFS_ROOT/lib/python/site-packages
EoF
