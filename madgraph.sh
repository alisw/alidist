package: madgraph
version: "%(tag_basename)s"
tag: "v3.5.13"
source: https://github.com/mg5amcnlo/mg5amcnlo
requires:
  - Python-modules
  - curl
  - zlib
  - fastjet
  - lhapdf
  - pythia
  - ninja
license: GPL-3.0
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a --no-specials --no-devices  --chmod=ug=rwX --exclude '**/.git' --delete --delete-excluded "$SOURCEDIR/" "$BUILDDIR/"

# Pythia8 Makefile.inc could have a space after "-rpath," which causes the linker to fail to find HepMC2. This ensures there is no space.
sed -i -E \
    -e "s|HEPMC2_LIB=.*|HEPMC2_LIB=-L${HEPMC_ROOT}/lib -Wl,-rpath,${HEPMC_ROOT}/lib -lHepMC|" \
    -e "s|HEPMC2_INCLUDE=.*|HEPMC2_INCLUDE=-I${HEPMC_ROOT}/include|" \
    "$PYTHIA_ROOT/share/Pythia8/examples/Makefile.inc"

# install internal packages
cd "$BUILDDIR"
cat << EOF >> install.dat
set lhapdf $LHAPDF_ROOT/bin/lhapdf-config
set fastjet $FASTJET_ROOT/bin/fastjet-config
set pythia8_path $PYTHIA_ROOT
install oneloop
install collier
install RunningCoupling
install QCDLoop
install MadAnalysis5 --with_zlib=$ZLIB_ROOT --with_fastjet=$FASTJET/lib
install mg5amc_py8_interface
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

# FastJet was built with CGAL support; MA5 links against -lCGAL and -lgmp but
# only passes -L$FASTJET/lib. This ensures the linker can find CGAL and GMP.
export LIBRARY_PATH="${CGAL_ROOT:+$CGAL_ROOT/lib:}${GMP_ROOT:+$GMP_ROOT/lib:}${LIBRARY_PATH:-}"

./bin/mg5_aMC install.dat

# cleanup after build
rm install.dat
find HEPTools -name "*.log" -delete
rm -rf HEPTools/oneloop/OneLOop*
rm -rf HEPTools/collier/COLLIER*
find QCDLoop -mindepth 1 -maxdepth 1 -not -name include -not -name lib -not -name share -exec rm -rf {} \;
rm *.tgz
rm vendor/*tar.gz

# change paths in configuration file for package relocation
sed -i.deleteme -e "s|$BUILDDIR|/TEMP_PATH/|" input/mg5_configuration.txt
rm -f input/mg5_configuration.txt.deleteme
mv input/mg5_configuration.txt input/mg5_configuration.txt.buildtime
echo "# Dummy configuration file" > input/mg5_configuration.txt
rsync -a "$BUILDDIR/" "$INSTALLROOT/"

#ModuleFile
mkdir -p "$INSTALLROOT"/etc/modulefiles
alibuild-generate-module > "$INSTALLROOT"/etc/modulefiles/"$PKGNAME"

cat << EOF >> "$INSTALLROOT"/etc/modulefiles/"$PKGNAME"
set MADGRAPH_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MADGRAPH_ROOT \$MADGRAPH_ROOT
prepend-path PATH \$MADGRAPH_ROOT/bin
# Copy mg5_configuration.txt done at build time to /tmp and patch it with runtime env var paths
set MADGRAPH_BASE /tmp/madgraph-\$version
setenv MADGRAPH_BASE \$MADGRAPH_BASE
set mg5_cfg \$MADGRAPH_BASE/mg5_configuration.txt
if { ![ file exists \$mg5_cfg ] } {
    exec mkdir -p \$MADGRAPH_BASE
    exec cp "\$MADGRAPH_ROOT/input/mg5_configuration.txt.buildtime" \$mg5_cfg
    exec sed -i \
        -e "s|^fastjet *=.*|fastjet = $::env(FASTJET)/bin/fastjet-config|" \
        -e "s|^pythia8_path *=.*|pythia8_path = $::env(PYTHIA_ROOT)|" \
        -e "s|/TEMP_PATH/|\$MADGRAPH_ROOT|g" \
        -e "s|^lhapdf *=.*|lhapdf = $::env(LHAPDF_ROOT)/bin/lhapdf-config|" \
        \$mg5_cfg
}
EOF
