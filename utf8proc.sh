package: utf8proc
version: "v2.5.0"
tag: v2.5.0
source: https://github.com/JuliaStrings/utf8proc
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
prefer_system: "(?!osx)"
prefer_system_check: \
  brew --prefix utf8proc > /dev/null;
  if [ $? -ne 0 ]; then printf "Use brew install utf8proc"; exit 1; fi
---
rsync -a --delete --exclude "**/.git" $SOURCEDIR/ .
make ${JOBS+-j $JOBS} install prefix=$INSTALLROOT

mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME

cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set PKGROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$PKGROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
