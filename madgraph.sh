package: madgraph
version: "%(tag_basename)s"
tag: "v3.5.2"
source: https://github.com/alisw/MadGraph
requires:
  - Python-modules
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" "$BUILDDIR/"

# install internal packages 
cd "$BUILDDIR"
cat << EOF >> install.dat
install oneloop
install ninja
install collier
install RunningCoupling
install QCDLoop
install MadAnalysis5
EOF

./bin/mg5_aMC install.dat

# cleanup after build
rm install.dat
rm HEPTools/ninja/ninja_install.log 
rm HEPTools/oneloop/oneloop_install.log
rm HEPTools/collier/collier_install.log
rm HEPTools/madanalysis5/madanalysis5_install.log
rm -rf HEPTools/ninja/Ninja 
rm -rf HEPTools/oneloop/OneLOop*
rm -rf HEPTools/collier/COLLIER*
find QCDLoop -mindepth 1 -maxdepth 1 -not -name include -not -name lib -not -name share -exec rm -rf {} \;
rm *.tgz
rm vendor/*tar.gz

# change paths in conifguration file for package relocation
sed -i.deleteme -e "s|$BUILDDIR|$INSTALLROOT|" input/mg5_configuration.txt
rm -f input/mg5_configuration.deleteme
rsync -a "$BUILDDIR/" "$INSTALLROOT/"

#ModuleFile
mkdir -p "$INSTALLROOT"/etc/modulefiles
alibuild-generate-module > "$INSTALLROOT"/etc/modulefiles/"$PKGNAME"

cat << EOF >> "$INSTALLROOT"/etc/modulefiles/"$PKGNAME"
set MADGRAPH_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MADGRAPH_ROOT \$MADGRAPH_ROOT
prepend-path PATH \$MADGRAPH_ROOT/bin

EOF
