package: SWAN
version: "1.0"
requires:
  - Python-modules
env:
  SSL_CERT_FILE: "$(export PYTHONPATH=$PYTHON_MODULES_ROOT/lib/python2.7/site-packages:$PYTHONPATH; export PATH=$PYTHON_ROOT/bin:$PATH; export LD_LIBRARY_PATH=$PYTHON_ROOT/lib:$LD_LIBRARY_PATH; python -c \"import certifi; print certifi.where()\")"
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/lib/python2.7/site-packages:$PYTHONPATH
prefer_system: (?!slc5)
prefer_system_check:
  python -c 'import IPython; import ipykernel'
---
#!/bin/bash -ex

# Install extra packages with pip
pip install --install-option="--prefix=$INSTALLROOT" "ipython"
pip install --install-option="--prefix=$INSTALLROOT" "ipykernel"
# Remove useless stuff
rm -rvf $INSTALLROOT/lib/python*/test
find $INSTALLROOT/lib/python*                                              \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}'                                                    \;

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
module load BASE/1.0 ${PYTHON_MODULES_VERSION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
# Our environmen:$PYTHONPATH
setenv SWAN_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(SWAN_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(SWAN_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(SWAN_ROOT)/lib")
prepend-path PYTHONPATH $::env(SWAN_ROOT)/lib/python2.7/site-packages
EoF
