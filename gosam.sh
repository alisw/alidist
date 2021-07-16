package: GoSam
version: "%(tag_basename)s"
tag: "GoSam95"
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
unset HTTP_PROXY # unset this to build on slc6 system

wget "http://gosam.hepforge.org/gosam_installer.py"
chmod 0755 ./gosam_installer.py
./gosam_installer.py -b -v --prefix=$INSTALLROOT

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set GOSAM_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GOSAM_ROOT \$GOSAM_ROOT
prepend-path PATH \$GOSAM_ROOT/bin
prepend-path LD_LIBRARY_PATH \$GOSAM_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles