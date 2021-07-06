package: madgraph
version: "%(tag_basename)s"
tag: "v2.8.1"
source: https://github.com/alisw/MadGraph
requires:
 - "Python:slc.*"
 - "Python-system:(?!slc.*)"
 - fastjet
 - GoSam
 - lhapdf
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

echo "generate e+ e- > u u~" >> test.mg
echo "output" >> test.mg
echo "quit()" >> test.mg

bin/mg5_aMC -f test.mg
rm -rf PROC_sm_0
rm test.mg

rsync -a --exclude='**/.git' --delete --delete-excluded ./ $INSTALLROOT/

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME

cat << EOF >> $INSTALLROOT/etc/modulefiles/$PKGNAME
set MADGRAPH_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MADGRAPH_ROOT \$MADGRAPH_ROOT
prepend-path PATH \$MADGRAPH_ROOT/bin

EOF
