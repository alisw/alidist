package: madgraph
version: "%(tag_basename)s"
tag: "v3.5.2"
source: https://github.com/alisw/MadGraph
requires:
  - Python-modules
  - curl
  - cgal
  - GMP
  - fastjet
  - ROOT
  - zlib
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

# MadGraph uses wget for non macOSx systems, but this might not be available.
# This is a workaround using curl (similar procedure in SHERPA)
if ! (command -v wget > /dev/null); then
    echo "wget not found, using curl"
    mkdir -p tmpwget
    cat > tmpwget/wget << EOF
#!/bin/sh
outfile=""
url=""
for arg in "\$@"; do
  case "\$arg" in
    --output-document=*)
      outfile="\${arg#--output-document=}"
      ;;
    -*)
      ;;
    *)
      url="\$arg"
      ;;
  esac
done
if [ -z "\$outfile" ]; then
  exec curl -fLO "\$url"
else
  exec curl -fL "\$url" -o "\$outfile"
fi
EOF
    chmod +x tmpwget/wget
    export PATH="$PWD/tmpwget:$PATH"
fi

# Set library paths for MadAnalysis5 FastJet linking, otherwise package build will fail
# This will be shown only in the log, but not in the final exit code because after a while the package will be skipped and the build will succeed
export LIBRARY_PATH="${CGAL_ROOT:+$CGAL_ROOT/lib:}${GMP_ROOT:+$GMP_ROOT/lib:}$LIBRARY_PATH"

./bin/mg5_aMC install.dat &
# Link to ZLIB in HEPTools for MadAnalysis5, no other way to pass this dependency otherwise
while [ ! -d HEPTools ]; do sleep 1; done
if [ -n "$ZLIB_ROOT" ]; then
  ln -s "$ZLIB_ROOT" HEPTools/zlib
fi
wait

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
