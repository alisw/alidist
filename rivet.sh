package: Rivet
version: "%(tag_basename)s"
tag: "3.1.8-alice1"
source: https://github.com/alisw/rivet.git
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
prepend_path:
  PYTHONPATH: "$RIVET_ROOT/lib/python/site-packages"
---
#!/bin/bash -e
#
# For testing 
#
#   aliBuild  -a slc7_x86-64 --docker-image registry.cern.ch/alisw/slc7-builder:latest. Rivet
#
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR"/ ./
 
(
unset PYTHON_VERSION
autoreconf -ivf

# Write script to set-up variables to point to third-party tools
cat <<EOF > rivet_3rdparty.sh
ret=true
env_err() {
    echo "\${@}" > /dev/stderr
    ret=false
}

if hash HepMC3-config 2>/dev/null && test x\$HEPMC3_ROOT = x ; then
   HEPMC3_ROOT=\`HepMC3-config --prefix\`
fi
if hash yoda-config 2>/dev/null && test x\$YODA_ROOT = x ; then
   YODA_ROOT=\`yoda-config --prefix\`
fi
if hash fastjet-config 2> /dev/null && test x\$FASTJET_ROOT = x ; then
   FASTJET_ROOT=\`fastjet-config --prefix\`
fi

test x\$HEPMC3_ROOT = x  && env_err HepMC3 not found
test x\$YODA_ROOT = x    && env_err Yoda not found
test x\$FASTJET_ROOT = x && env_err FastJet not found

\$ret
EOF

# source our newly created script 
source rivet_3rdparty.sh 

CGAL_LDFLAGS="-L${CGAL_ROOT}/lib"
GMP_LDFLAGS="-L${GMP_ROOT}/lib"
LOCAL_LDFLAGS="${CGAL_LDFLAGS} ${GMP_LDFLAGS}"
case $ARCHITECTURE in
    osx*)
        ./configure --prefix="$INSTALLROOT"            \
                    --disable-silent-rules             \
                    --disable-doxygen                  \
                    --with-yoda="$YODA_ROOT"           \
                    --with-hepmc3="$HEPMC3_ROOT"       \
                    --with-fastjet="$FASTJET_ROOT"     \
                    LDFLAGS="${LOCAL_LDFLAGS}"
        ;;
    *)
        LOCAL_LDFLAGS="${LOCAL_LDFLAGS} -Wl,--no-as-needed"
        ./configure --prefix="$INSTALLROOT"                             \
                    --disable-silent-rules                              \
                    --disable-doxygen                                   \
                    --with-yoda="$YODA_ROOT"                            \
                    --with-hepmc3="$HEPMC3_ROOT"                        \
                    --with-fastjet="$FASTJET_ROOT"                      \
                    LDFLAGS="${LOCAL_LDFLAGS}"                          \
                    CYTHON="$PYTHON_MODULES_ROOT/bin/cython"
  ;;
esac

# Fix-up rivet-build to include LDFLAGS - needed _before_ bulding 
# After 3.1.9 this will not be needed. 
SED_EXPR="s|^myldflags=\"\(.*\)\"|myldflags=\"\1 ${LOCAL_LDFLAGS}\"|"
sed -e "${SED_EXPR}" bin/rivet-build > bin/rivet-build.0
mv bin/rivet-build bin/rivet-build.orig
mv bin/rivet-build.0 bin/rivet-build
chmod 0755 bin/rivet-build
# Remove -L/usr/lib from pyext/build.py 
sed -e 's,-L/usr/lib[^ /"]*,,g' pyext/build.py > pyext/build.py.0
mv pyext/build.py pyext/build.py.orig
mv pyext/build.py.0 pyext/build.py
# Make pyext/build.py executable
chmod 0755 pyext/build.py
# Now build 
make ${JOBS+-j $JOBS}
make install
)

# Remove libRivet.la
rm -f "$INSTALLROOT"/lib/libRivet.la

# Install shell-script fragment to set-up variables 
cp rivet_3rdparty.sh "$INSTALLROOT"/etc/rivet_3rdparty.sh

# Dependencies relocation: rely on runtime environment.  That is,
# specific paths in the generated script are replaced by expansions of
# the relevant environment variables.
SED_EXPR="s!x!x!"  # noop
for P in $REQUIRES $BUILD_REQUIRES; do
  UPPER=$(echo "$P" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  EXPAND=$(eval echo \$"${UPPER}"_ROOT)
  if [ -z "$EXPAND" ]; then
      echo "Environment variable ${UPPER}_ROOT not set"
  fi
  [[ $EXPAND ]] || continue
  echo "Environment says ${UPPER} is at ${EXPAND}"
  SED_EXPR="$SED_EXPR; s!$EXPAND!\$${UPPER}_ROOT!g"
done

# Create line to source 3rdparty.sh to be inserted into 
# rivet-config and rivet-build 
cat << EOF > source3rd
test -f \$prefix/etc/rivet_3rdparty.sh && source \$prefix/etc/rivet_3rdparty.sh
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

# Make sure we get the YODA version we need 
if test "x$YODA_VERSION" != "x" && test "x$YODA_REVISION" != "x" ; then 
    YODA_NEEDED=${YODA_VERSION}-${YODA_REVISION}
else 
    YODA_NEEDED=$(basename "$YODA_ROOT")
fi 

# Make sure we get the FASTJET version we need 
if test "x$FASTJET_VERSION" != "x" && test "x$FASTJET_REVISION" != "x" ; then 
    FASTJET_NEEDED=${FASTJET_VERSION}-${FASTJET_REVISION}
else 
    FASTJET_NEEDED=$(basename "$FASTJET_ROOT")
fi 

# Make sure we get the HEPMC3 version we need 
if test "x$HEPMC3_VERSION" != "x" && test "x$HEPMC3_REVISION" != "x" ; then 
    HEPMC3_NEEDED=${HEPMC3_VERSION}-${HEPMC3_REVISION}
else 
    HEPMC3_NEEDED=$(basename "$HEPMC3_ROOT")
fi 

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 YODA/$YODA_NEEDED fastjet/$FASTJET_NEEDED HepMC3/$HEPMC3_NEEDED
# Our environment 
set RIVET_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv RIVET_ROOT $RIVET_ROOT
setenv RIVET_ANALYSIS_PATH $RIVET_ROOT/lib/Rivet
setenv RIVET_DATA_PATH $RIVET_ROOT/share/Rivet
prepend-path PYTHONPATH \$RIVET_ROOT/lib/$PYVER/site-packages
prepend-path PYTHONPATH \$RIVET_ROOT/lib64/$PYVER/site-packages
prepend-path PATH \$RIVET_ROOT/bin
prepend-path LD_LIBRARY_PATH \$RIVET_ROOT/lib

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


#
# EOF
#

