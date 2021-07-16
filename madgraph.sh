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

# Create empty template directory for MadLoop5 resources which is needed 
# during processing but cannot be part of the MadGraph repository itself
# as git does not track empty directories
mkdir -p Template/loop_material/StandAlone/SubProcesses/MadLoop5_resources

# Do some basic initialization of MadGraph
echo "generate e+ e- > u u~" >> test.mg
echo "output" >> test.mg
echo "quit()" >> test.mg

bin/mg5_aMC -f test.mg
rm -rf PROC_sm_0
rm test.mg

# install dependency on other packages
# Needed at least: 
# - oneloop
# - collier
# - ninja
heptools=(collier oneloop ninja)
for tool in ${heptools[@]}; do
  echo "install $tool" >> install.mg
done

bin/mg5_aMC -f install.mg
rm install.mg
rm vendor/*.tar.gz
heptools=(collier oneloop ninja)
for tool in ${heptools[@]}; do
  rm HEPTools/$tool/$tool\_install.log
done

# install cuttools and IREGI
MGBASE=$PWD
cd $MGBASE/vendor/CutTools
make
cd $MGBASE/vendor/IREGI/src
make
cd $MGBASE

rsync -a --exclude='**/.git' --delete --delete-excluded ./ $INSTALLROOT/

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME

cat << EOF >> $INSTALLROOT/etc/modulefiles/$PKGNAME
set MADGRAPH_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MADGRAPH_ROOT \$MADGRAPH_ROOT
prepend-path PATH \$MADGRAPH_ROOT/bin

EOF
