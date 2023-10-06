package: Rivet
version: "%(tag_basename)s"
tag: "rivet-3.1.8"
source: https://gitlab.com/hepcedar/rivet.git
requires:
  - HepMC3
  - YODA
  - fastjet
  - GMP
  - "Python:(?!osx)"
  - "Python-modules:(?!osx)"
  - "Python-system:(osx.*)"
build_requires:
  - GCC-Toolchain:(?!osx)
  - YODA
  - Python
prepend_path:
  PYTHONPATH: $RIVET_ROOT/lib/python/site-packages
---
#!/bin/bash -e
#
# For testing 
#
#   alienv enter ./module 
#   export ALIBUILD_ARCH_PREFIX=el7-x86_64/Packages
#   export WORK_DIR=/cvmfs/alice.cern.ch
#   . ${PYTHONHOME}/etc/profile.d/init.sh
#   . ${HEPMC3_ROOT}/etc/profile.d/init.sh
#   . ${FASTJET}/etc/profile.d/init.sh
#   export WORK_DIR=`pwd`/sw
#   export ALIBUILD_ARCH_PREFIX=
#   module load `pwd`/sw/slc7_x86-64/YODA/latest/etc/modulefiles/YODA 
#   . `pwd`/sw/slc7_x86-64/YODA/latest/etc/profile.d/init.sh
#   export WORK_DIR=
#   aliBuild build \
#     --disable Python-modules,boost,defaults-release,CMake,HepMC3,ROOT,YODA,cgal,fastjet \
#     --always-prefer-system \
#     --debug \
#     Rivet
# 
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./
 
(
unset PYTHON_VERSION
autoreconf -ivf

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
	./configure --prefix="$INSTALLROOT"    	                        \
		    --disable-silent-rules                              \
		    --disable-doxygen                  			\
		    --with-yoda="$YODA_ROOT"           			\
		    --with-hepmc3="$HEPMC3_ROOT"       			\
		    --with-fastjet="$FASTJET_ROOT"     			\
		    LDFLAGS="${LOCAL_LDFLAGS}"                          \
		    CYTHON="$PYTHON_MODULES_ROOT/share/python-modules/bin/cython"
  ;;
esac

# Fix-up rivet-build to include LDFLAGS - needed _before_ bulding 
# After 3.1.9 this will not be needed. 
SED_EXPR="s|^myldflags=\"\(.*\)\"|myldflags=\"\1 ${LOCAL_LDFLAGS}\"|"
cat bin/rivet-build | sed -e "${SED_EXPR}" > bin/rivet-build.0
mv bin/rivet-build bin/rivet-build.orig
mv bin/rivet-build.0 bin/rivet-build
chmod 0755 bin/rivet-build
# Remove -L/usr/lib from pyext/build.py 
cat pyext/build.py | sed -e 's,-L/usr/lib[^ /"]*,,g' > pyext/build.py.0
mv pyext/build.py pyext/build.py.orig
mv pyext/build.py.0 pyext/build.py
chmod 0755 pyext/build.py
# Now build 
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

# Modify rivet-config script to use environment 
cat $INSTALLROOT/bin/rivet-config | sed -e "$SED_EXPR" > $INSTALLROOT/bin/rivet-config.0
mv $INSTALLROOT/bin/rivet-config.0 $INSTALLROOT/bin/rivet-config
chmod 0755 $INSTALLROOT/bin/rivet-config

# Modify rivet-build script to use environment.  We also
# add in the LDFLAGS set at compile time so that when building Rivet
# plugins we use the same flags as when Rivet is built.
# Modify rivet-build script to use environment  
cat $INSTALLROOT/bin/rivet-build | sed -e  "$SED_EXPR" > $INSTALLROOT/bin/rivet-build.0
mv $INSTALLROOT/bin/rivet-build.0 $INSTALLROOT/bin/rivet-build
chmod 0755 $INSTALLROOT/bin/rivet-build

# Make symlink in library dir for Python
PYVER="$(basename $(find $INSTALLROOT/lib -type d -name 'python*'))"

pushd $INSTALLROOT/lib
ln -s ${PYVER} python
popd

# Make sure we get the YODA version we need 
if test "x$YODA_VERSION" != "x" && test "x$YODA_REVISION" != "x" ; then 
    YODA_NEEDED=${YODA_VERSION}-${YODA_REVISION}
else 
    YODA_NEEDED=`basename $YODA_ROOT` 
fi 

# Make sure we get the FASTJET version we need 
if test "x$FASTJET_VERSION" != "x" && test "x$FASTJET_REVISION" != "x" ; then 
    FASTJET_NEEDED=${FASTJET_VERSION}-${FASTJET_REVISION}
else 
    FASTJET_NEEDED=`basename $FASTJET_ROOT` 
fi 

# Make sure we get the HEPMC3 version we need 
if test "x$HEPMC3_VERSION" != "x" && test "x$HEPMC3_REVISION" != "x" ; then 
    HEPMC3_NEEDED=${HEPMC3_VERSION}-${HEPMC3_REVISION}
else 
    HEPMC3_NEEDED=`basename $HEPMC3_ROOT` 
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
