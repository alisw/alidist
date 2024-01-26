package: MachineLearningHEP
version: "%(tag_basename)s"
tag: "run3"
source: https://github.com/alisw/MachineLearningHEP
requires:
  - Python-modules
build_requires:
  - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: ${MACHINELEARNINGHEP_ROOT}/lib/python/site-packages
incremental_recipe: |
  pip install -e .
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
mkdir -p etc/modulefiles
MODULEFILE="etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
set MLHEP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$MLHEP_ROOT/lib/python/site-packages
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
