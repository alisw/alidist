package: GenTopo
version: "%(tag_basename)s"
tag: "nightly-20230105"
source: https://github.com/AliceO2Group/O2DPG.git
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
mkdir $INSTALLROOT/bin
cp $SOURCEDIR/DATA/tools/epn/gen_topo*.sh $INSTALLROOT/bin

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin > etc/modulefiles/$PKGNAME
cat << EOF >> etc/modulefiles/$PKGNAME
set GenTopo_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GenTopo_ROOT \$GenTopo_ROOT
setenv GenTopo_RELEASE \$version
setenv GenTopo_VERSION $PKGVERSION
EOF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
