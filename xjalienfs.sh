package: xjalienfs
version: "%(tag_basename)s"
tag: "1.3.0"
source: https://gitlab.cern.ch/jalien/xjalienfs.git
requires:
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - XRootD
 - AliEn-Runtime
 - Python-modules
build_requires:
 - alibuild-recipe-tools
---
#!/bin/bash -e

PIPOPTION="--user"
if [ ! "X$VIRTUAL_ENV" = X ]; then
  PIPOPTION=""
fi

env PYTHONUSERBASE="$INSTALLROOT" ALIBUILD=1 python3 -m pip install --ignore-installed $PIPOPTION file://${SOURCEDIR}

# Make sure all the tools use the correct python
mkdir -p "$INSTALLROOT/bin"
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

if [ -d ${INSTALLROOT}/lib ]; then
  pushd ${INSTALLROOT}/lib
      ln -nfs python* python
  popd
fi

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
if [ -z "$VIRTUAL_ENV" ]; then
  echo 'prepend-path PYTHONPATH $XJALIENFS_ROOT/lib/python/site-packages'
fi | alibuild-generate-module --bin --extra > "$MODULEDIR/$PKGNAME"
