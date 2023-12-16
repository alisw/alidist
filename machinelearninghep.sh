package: MachineLearningHEP
version: "%(tag_basename)s"
tag: "run3"
source: https://github.com/alisw/MachineLearningHEP
requires:
  - Python-modules
prepend_path:
  PYTHONPATH: ${MACHINELEARNINGHEP_ROOT}/lib/python/site-packages
---
#!/bin/bash -e

PIPOPTIONS=""

DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
[[ "$DEVEL_SOURCES" != "$SOURCEDIR" ]] && PIPOPTIONS+=" -e"

env -u VIRTUAL_ENV ALIBUILD=1 \
    python3 -m pip install --force-reinstall \
    --target="$INSTALLROOT/lib/python/site-packages" \
    ${PIPOPTIONS} "file://$SOURCEDIR"

# rm -rf "${INSTALLROOT:?}/bin"
mv "$INSTALLROOT/lib/python/site-packages/bin" "$INSTALLROOT/bin"

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
            ${PYTHON_MODULES_REVISION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
# Our environment
set MLHEP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$MLHEP_ROOT/bin
prepend-path PYTHONPATH \$MLHEP_ROOT/lib/python/site-packages
EoF
