package: Rivet
version: "%(tag_basename)s"
tag: "3.1.8"
source: https://gitlab.com/hepcedar/rivet
requires:
  - YODA
  - fastjet
  - HepMC3
  - "Python:(?!osx)"
  - "Python-modules:(?!osx)"
  - "Python-system:(osx.*)"
build_requires:
  - GCC-Toolchain:(?!osx)
prepend_path:
  PYTHONPATH: $RIVET_ROOT/lib/python3.9/site-packages
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
  ;;
  *)
    ARCH_LDFLAGS="-Wl,--no-as-needed"
  ;;
esac

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

export LDFLAGS="$ARCH_LDFLAGS"
export LIBRARY_PATH="$LD_LIBRARY_PATH"

(
unset PYTHON_VERSION
autoreconf -ivf
case $ARCHITECTURE in
  osx*)
      ./configure                                 \
	  --prefix="$INSTALLROOT"                   \
	  --disable-doxygen                         \
	  --with-yoda="$YODA_ROOT"                  \
	  --with-hepmc="$HEPMC_ROOT"                \
	  --with-fastjet="$FASTJET_ROOT"
  ;;
  *)
      ./configure                                 \
	  --prefix="$INSTALLROOT"                   \
	  --disable-doxygen                         \
	  --with-yoda="$YODA_ROOT"                  \
	  --with-hepmc="$HEPMC_ROOT"                \
	  --with-fastjet="$FASTJET_ROOT"            \
	  CYTHON="$PYTHON_MODULES_ROOT/share/python-modules/bin/cython"
  ;;
esac
make -j$JOBS
make install
)

# Remove libRivet.la
rm $INSTALLROOT/lib/libRivet.la

# Dependencies relocation: rely on runtime environment.  That is,
# specific paths in the generated script are replaced by expansions of
# the relevant environment variables.
SED_EXPR="s!x!x!"  # noop
for P in $REQUIRES $BUILD_REQUIRES; do
  UPPER=$(echo $P | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  EXPAND=$(eval echo \$${UPPER}_ROOT)
  [[ $EXPAND ]] || continue
  SED_EXPR="$SED_EXPR; s!$EXPAND!\$${UPPER}_ROOT!g"
done
cat $INSTALLROOT/bin/rivet-config | sed -e "$SED_EXPR" > $INSTALLROOT/bin/rivet-config.0
mv $INSTALLROOT/bin/rivet-config.0 $INSTALLROOT/bin/rivet-config
chmod 0755 $INSTALLROOT/bin/rivet-config
PYVER="$(basename $(find $INSTALLROOT/lib -type d -name 'python*'))"

# We do a similar thing for the `rivet-build` script so that we again
# refer to specific installations by environment variable.  We also
# add in the LDFLAGS set at compile time so that when building Rivet
# plugins we use the same flags as when Rivet is built.
cat $INSTALLROOT/bin/rivet-build | sed -e 's,^myldflags="\([^"]*\)",myldflags="\1 $LDFLAGS",' -e "$SED_EXPR" > $INSTALLROOT/bin/rivet-build.0
mv $INSTALLROOT/bin/rivet-build.0 $INSTALLROOT/bin/rivet-build

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
module load BASE/1.0 ${CGAL_REVISION:+cgal/$CGAL_VERSION-$CGAL_REVISION} ${GMP_REVISION:+GMP/$GMP_VERSION-$GMP_REVISION} YODA/$YODA_VERSION-$YODA_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION
# Our environment
set RIVET_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv RIVET_ROOT \$RIVET_ROOT
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
if { [catch {exec which kpsewhich > /dev/null 2>&1 && kpsewhich -var-value TEXINPUTS} tempTEX] } { 
    set Old_TEXINPUTS [ exec sh -c "which kpsewhich > /dev/null 2>&1 && kpsewhich -var-value TEXINPUTS" ] 
} else {
    set Old_TEXINPUTS \$tempTEX  
}

set Extra_RivetTEXINPUTS \$RIVET_ROOT/share/Rivet/texmf/tex//
setenv TEXINPUTS  \$Old_TEXINPUTS:\$Extra_RivetTEXINPUTS
setenv LATEXINPUTS \$Old_TEXINPUTS:\$Extra_RivetTEXINPUTS
EoF
