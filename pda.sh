package: PDA
version: "%(tag_basename)s"
tag: 12.2.0
source: https://github.com/AliceO2Group/pda.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - kernel-devel
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded "$SOURCEDIR/" ./
./configure --debug=false --numa=true --modprobe=true --prefix="$INSTALLROOT" --extra=PDA_SKIP_UNLOCK_FAILURE
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > "etc/modulefiles/$PKGNAME"
cat >> "etc/modulefiles/$PKGNAME" <<EoF
# Our environment
setenv PDA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
mkdir -p "$INSTALLROOT/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"
