package: xjalienfs
version: "%(tag_basename)s"
tag: 1.0.0
source: https://gitlab.cern.ch/jalien/xjalienfs.git
requires:
 - "OpenSSL:(?!osx)"
 - "osx-system-openssl:(osx.*)"
 - XRootD
 - AliEn-Runtime
 - Python-modules
---
#!/bin/bash -e

# env PYTHONUSERBASE="$INSTALLROOT" pip3 install --user -r alibuild_requirements.txt
env PYTHONUSERBASE="$INSTALLROOT" ALIBUILD=1 pip3 install --user file://${SOURCEDIR}
XJALIENFS_SITEPACKAGES=$(find ${INSTALLROOT} -name site-packages)

ALIEN_PY=$(find ${INSTALLROOT} -name alien.py)

cp -r $SOURCEDIR/bin ${INSTALLROOT}/bin
cp ${ALIEN_PY} ${INSTALLROOT}/bin/alien.py
chmod +x ${INSTALLROOT}/bin/*


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
prepend-path PYTHONPATH $XJALIENFS_SITEPACKAGES
prepend-path PATH $INSTALLROOT/bin
EoF
