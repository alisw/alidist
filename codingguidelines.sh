package: CodingGuidelines
version: "%(tag_basename)s"
tag: master
source: https://github.com/AliceO2Group/CodingGuidelines
---
#!/bin/sh

# Simply install the .clang-format for the other packages to find it
rsync -a --ignore-existing $SOURCEDIR/.clang-format $INSTALLROOT

#ModuleFile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
global version
puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Our environment
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
