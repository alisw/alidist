package: Rivet
version: "%(tag_basename)s"
tag: "rivet-4.1.0"
source: https://gitlab.com/hepcedar/rivet.git
requires:
  - HepMC3
  - YODA
  - fastjet
  - cgal
  - GMP
  - Python
  - Python-modules
build_requires:
  - GCC-Toolchain:(?!osx)
  - Python
  - make
  - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: "$RIVET_ROOT/lib/python/site-packages"
---
#!/bin/bash -e
#
# For testing 
#
#   aliBuild  -a slc7_x86-64 --docker-image registry.cern.ch/alisw/slc7-builder:latest. Rivet
#
rsync -a --chmod=ugo=rwX --delete --exclude '**/.git' --delete-excluded "$SOURCEDIR"/ ./
 
autoreconf -ivf

case $ARCHITECTURE in
    osx*)
        export HDF5_ROOT=${HDF5_ROOT:-$(brew --prefix hdf5)}
        ;;
    *)
      EXTRA_LDFLAGS="-Wl,--no-as-needed"
    ;;
esac

./configure --prefix="$INSTALLROOT"                             \
            --disable-silent-rules                              \
            --disable-doxygen                                   \
            --with-yoda="$YODA_ROOT"                            \
            --with-hepmc3="$HEPMC3_ROOT"                        \
            --with-fastjet="$FASTJET_ROOT"                      \
            LDFLAGS="${CGAL_ROOT:+-L${CGAL_ROOT}/lib} ${GMP_ROOT:+-L${GMP_ROOT}/lib} ${HDF5_ROOT:+-L${HDF5_ROOT}/lib} ${EXTRA_LDFLAGS}" \
            CPPFLAGS="${CGAL_ROOT:+-I${CGAL_ROOT}/include} ${GMP_ROOT:+-I${GMP_ROOT}/include} ${HDF5_ROOT:+-I${HDF5_ROOT}/include}" \
            CYTHON="$PYTHON_MODULES_ROOT/bin/cython"

# Remove -L/usr/lib from pyext/build.py 
sed -i.bak -e 's,-L/usr/lib[^ /"]*,,g' pyext/build.py
# Now build 
make ${JOBS+-j $JOBS}
make install

# Remove libRivet.la
rm -f "$INSTALLROOT"/lib/libRivet.la

# Create line to source 3rdparty.sh to be inserted into 
# rivet-config and rivet-build 
cat << EOF > source3rd
source $INSTALLROOT/etc/profile.d/init.sh
EOF

# Make back-up of original for debugging - disable execute bit
cp "$INSTALLROOT"/bin/rivet-config "$INSTALLROOT"/bin/rivet-config.orig
chmod 644 "$INSTALLROOT"/bin/rivet-config.orig
# Modify rivet-config script to use environment from rivet_3rdparty.sh
sed -e "$SED_EXPR" "$INSTALLROOT"/bin/rivet-config > "$INSTALLROOT"/bin/rivet-config.0
csplit "$INSTALLROOT"/bin/rivet-config.0 '/^datarootdir=/+1'
cat xx00 source3rd xx01 >  "$INSTALLROOT"/bin/rivet-config
chmod 0755 "$INSTALLROOT"/bin/rivet-config

# Make back-up of original for debugging - disable execute bit
cp "$INSTALLROOT"/bin/rivet-build "$INSTALLROOT"/bin/rivet-build.orig
chmod 644 "$INSTALLROOT"/bin/rivet-build.orig
# Modify rivet-build script to use environment from rivet_3rdparty.sh.  
sed -e  "$SED_EXPR" "$INSTALLROOT"/bin/rivet-build > "$INSTALLROOT"/bin/rivet-build.0
csplit "$INSTALLROOT"/bin/rivet-build.0 '/^datarootdir=/+1'
cat xx00 source3rd xx01 >  "$INSTALLROOT"/bin/rivet-build
chmod 0755 "$INSTALLROOT"/bin/rivet-build

# Make symlink in library dir for Python
PYVER="$(basename "$(find "$INSTALLROOT"/lib -type d -name 'python*')")"

pushd "$INSTALLROOT"/lib || exit 1
ln -s "${PYVER}" python
popd || exit 1


# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EoF
setenv RIVET_ROOT \$RIVET_ROOT
setenv RIVET_ANALYSIS_PATH \$RIVET_ROOT/lib/Rivet
setenv RIVET_DATA_PATH \$RIVET_ROOT/share/Rivet
prepend-path PYTHONPATH \$RIVET_ROOT/lib/$PYVER/site-packages
prepend-path PYTHONPATH \$RIVET_ROOT/lib64/$PYVER/site-packages

# Producing plots with (/rivet/bin/make-plots, in python) requires dedicated LaTeX packages
# which are not always there on the system (alidock, lxplus ...)
# -> need to point to such packages, actually shipped together with Rivet sources
# Consider the official source info in /rivet/rivetenv.sh to see what is needed
# (TEXMFHOME, HOMETEXMF, TEXMFCNF, TEXINPUTS, LATEXINPUTS)
# Here trying to keep the env variable changes to their minimum, i.e touch only TEXINPUTS, LATEXINPUTS
# Manual prepend-path for TEX variables
# catch option to fix compatibility issues with multiple systems
if { [catch {exec kpsewhich -var-value TEXINPUTS} brokenTEX] } {
    set Old_TEXINPUTS \$brokenTEX
} else {
    set Old_TEXINPUTS [ exec sh -c "kpsewhich -var-value TEXINPUTS" ]
}

set Extra_RivetTEXINPUTS \$RIVET_ROOT/share/Rivet/texmf/tex//
setenv TEXINPUTS  \$Old_TEXINPUTS:\$Extra_RivetTEXINPUTS
setenv LATEXINPUTS \$Old_TEXINPUTS:\$Extra_RivetTEXINPUTS
EoF

