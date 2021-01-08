package: xjalienfs
version: "%(tag_basename)s"
tag: "1.2.8"
source: https://gitlab.cern.ch/jalien/xjalienfs.git
requires:
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - XRootD
 - AliEn-Runtime
 - Python-modules
---
#!/bin/bash -e

PIPOPTION="--user"
if [ ! "X$VIRTUAL_ENV" = X ]; then
  PIPOPTION=""
fi

env PYTHONUSERBASE="$INSTALLROOT" ALIBUILD=1 python3 -m pip install --ignore-installed $PIPOPTION file://${SOURCEDIR}

if [ "X$VIRTUAL_ENV" = X ]; then
  sed -i".bak" 's/#!.*python.*/#!\/usr\/bin\/env python3/' ${INSTALLROOT}/bin/*
  rm -v ${INSTALLROOT}/bin/*.bak
  
   # Uniform Python library path
  pushd ${INSTALLROOT}
    pushd lib
      ln -nfs python* python
    popd
  popd
fi

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
EoF

if [ "X$VIRTUAL_ENV" = X ]; then
  cat >> "$MODULEFILE" << EoF
  prepend-path PYTHONPATH \$XJALIENFS_ROOT/lib/python/site-packages
EoF
fi
