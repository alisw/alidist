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
  - lhapdf-pdfsets
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
# the ninja package here is the one-loop reduction library used by MadLoop for NLO, not the build tool
# MadAnalysis5 fails to start on CVMFS, but it still works locally, so we install it anyway to allow users to run it if they
# really want to. On CVMFS it creates a warning, but doesn't prevent MadGraph from running successfully.
cd "$BUILDDIR"
cat << EOF >> install.dat
set lhapdf $LHAPDF_ROOT/bin/lhapdf-config
set fastjet $FASTJET_ROOT/bin/fastjet-config
set pythia8_path $PYTHIA_ROOT
install oneloop
install ninja
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

# The Pythia8 1.3 interface for MadGraph does not compile against Pythia 8.318, and mg5_aMC does not
# stop on that failure (shower=Pythia8 fails at runtime). A patch is applied to the interface source
# to make it compile, and the Makefile is modified to avoid plugin-macro clashes with the Pythia8Plugins headers.
# The interface is then built manually.
pushd HEPTools/MG5aMC_PY8_interface
sed -i 's/\bamcnlo_unitarised_interface\b/aMCatNLOHooks/g' MG5aMC_PY8_interface.cc
sed -i 's|$(CXX) $@.cc -o $@|$(CXX) -DNOPLUGIN $@.cc -o $@|' Makefile_mg5amc_py8_interface_static
grep -q aMCatNLOHooks MG5aMC_PY8_interface.cc && ! grep -q amcnlo_unitarised_interface MG5aMC_PY8_interface.cc || { echo "ERROR: MG5aMC_PY8_interface source patch did not apply" >&2; exit 1; }
grep -q NOPLUGIN Makefile_mg5amc_py8_interface_static || { echo "ERROR: MG5aMC_PY8_interface -DNOPLUGIN patch did not apply" >&2; exit 1; }
rm -rf static_library_dependencies
python3 compile.py "$PYTHIA_ROOT" "$BUILDDIR"
if [ ! -x MG5aMC_PY8_interface ]; then
  echo "ERROR: MG5aMC_PY8_interface was not built" >&2
  exit 1
fi
popd
# Same plugin-macro clash in the NLO+PS Pythia8 driver that MG copies into each NLO process.
sed -i 's/\$(CXX) \$(CXXFLAGS) /$(CXX) $(CXXFLAGS) -DNOPLUGIN /' \
  Template/NLO/MCatNLO/srcPythia8/Makefile Template/NLO/MCatNLO/srcPythia8/Makefile_hep
grep -q NOPLUGIN Template/NLO/MCatNLO/srcPythia8/Makefile || { echo "ERROR: MCatNLO -DNOPLUGIN patch did not apply" >&2; exit 1; }
# The NLO+PS Pythia8 driver takes the HepMC flags from "pythia8-config --hepmc2", i.e. from the Pythia
# Makefile.inc, which points to the HepMC of the machine Pythia was built on (not relocated on CVMFS).
# Use the HepMC loaded in the environment instead.
sed -i '/read HEPMCINCLIB <<< .*pythia8-config" --hepmc2)/a\  [ -n "$HEPMC_ROOT" ] \&\& HEPMCINCLIB="-I$HEPMC_ROOT/include -L$HEPMC_ROOT/lib -Wl,-rpath,$HEPMC_ROOT/lib -lHepMC"' \
  Template/NLO/MCatNLO/Scripts/MCatNLO_MadFKS_PYTHIA8.Script
grep -q 'HEPMCINCLIB="-I$HEPMC_ROOT/include' Template/NLO/MCatNLO/Scripts/MCatNLO_MadFKS_PYTHIA8.Script || { echo "ERROR: MCatNLO HepMC patch did not apply" >&2; exit 1; }

# With pdlabel=lhapdf, MG links the static libLHAPDF.a into each process. Our LHAPDF is built with
# -std=c++20, so its objects carry weak std::string instantiations; MG's pdf_lhapdf62.o (built
# without -std=c++20) needs those, which makes the linker extract LHAGlue.o from the archive,
# and that clashes with MadGraph's own Fortran glue ("multiple definition of lhapdf_getversion_" etc.).
# Link the shared library instead when it exists.
sed -i "s|^        lhalib = 'libLHAPDF.a'$|        lhalib = 'libLHAPDF.so' if os.path.exists(pjoin(lhalibdir, 'libLHAPDF.so')) else 'libLHAPDF.a'|" \
  madgraph/interface/common_run_interface.py
grep -q "lhalib = 'libLHAPDF.so' if" madgraph/interface/common_run_interface.py || { echo "ERROR: libLHAPDF.so patch did not apply" >&2; exit 1; }

# Loop/NLO process output (default output_dependencies=external) compiles vendor/CutTools and
# vendor/IREGI inside the MG5 install directory the first time it is needed. That fails on a
# read-only install (CVMFS), so they are built here instead.
make -C vendor/CutTools
make -C vendor/IREGI/src
for lib in vendor/CutTools/includects/libcts.a vendor/IREGI/src/libiregi.a; do
  [ -f "$lib" ] || { echo "ERROR: $lib was not built" >&2; exit 1; }
done
# NLO output also tries to compile vendor/StdHEP in place (writing src/make_opts first), which
# fails on a read-only install. StdHEP does not build on el9 and is only needed for NLO+PS with Pythia6/Herwig6,
# so we create a dummy file to make the build succeed and avoid the StdHEP build attempt.
echo "StdHEP not built in the ALICE package: NLO+PS with Pythia6/Herwig6 is unavailable" > vendor/StdHEP/fail

# cleanup after build
rm install.dat
rm -f MG5_debug  # log of the failed "install mg5amc_py8_interface" (rebuilt above); contains build paths
find HEPTools -name "*.log" -delete
rm -rf HEPTools/oneloop/OneLOop*
rm -rf HEPTools/collier/COLLIER*
find QCDLoop -mindepth 1 -maxdepth 1 -not -name include -not -name lib -not -name share -exec rm -rf {} \;
rm *.tgz
rm vendor/*tar.gz

# Make the configuration written at build time relocatable, editing it in place so
# that anything else MG5 wrote is kept.
# Paths inside the package are relative to the MG5 install directory
PYTHIA_REL="../../pythia/$(basename "$PYTHIA_ROOT")"
sed -i.deleteme \
    -e "s|$BUILDDIR/*|./|g" \
    -e "s|^pythia8_path *=.*|pythia8_path = $PYTHIA_REL|" \
    -e "s|^fastjet *=.*|fastjet = fastjet-config|" \
    -e "s|^lhapdf *=.*|lhapdf = lhapdf-config|" \
    -e "s|^#* *automatic_html_opening *=.*|automatic_html_opening = False|" \
    -e "s|^mg5_path *=|# mg5_path =|" \
    input/mg5_configuration.txt
rm -f input/mg5_configuration.txt.deleteme
rsync -a "$BUILDDIR/" "$INSTALLROOT/"

#ModuleFile
mkdir -p "$INSTALLROOT"/etc/modulefiles
alibuild-generate-module > "$INSTALLROOT"/etc/modulefiles/"$PKGNAME"

cat << EOF >> "$INSTALLROOT"/etc/modulefiles/"$PKGNAME"
set MADGRAPH_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv MADGRAPH_ROOT \$MADGRAPH_ROOT
prepend-path PATH \$MADGRAPH_ROOT/bin
# NLO executables need libninja.so (and friends) from HEPTools/lib at runtime and MadGraph only sets an rpath for collier
prepend-path LD_LIBRARY_PATH \$MADGRAPH_ROOT/HEPTools/lib
# NLO processes and MadAnalysis5 (which MadGraph forces to rebuild before each analysis) link
# against FastJet, which was built with CGAL: CGAL and GMP must be on the linker path.
prepend-path LIBRARY_PATH \$::env(CGAL_ROOT)/lib
prepend-path LIBRARY_PATH \$::env(GMP_ROOT)/lib
EOF
