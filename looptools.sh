package: looptools
version: "%(tag_basename)s"
tag: v2.16-alice1
source: https://github.com/alisw/LoopTools
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -a "$SOURCEDIR/" ./

./configure --prefix="$INSTALLROOT" --64

make ${JOBS+-j $JOBS}
make install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > "etc/modulefiles/$PKGNAME"
cat >> "etc/modulefiles/$PKGNAME" <<EoF
# Our environment
setenv LOOPTOOLS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(LOOPTOOLS_ROOT)/lib64
EoF
mkdir -p "$INSTALLROOT/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"
