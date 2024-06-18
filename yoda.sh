package: YODA
version: "%(tag_basename)s"
tag: "yoda-1.9.7"
source: https://gitlab.com/hepcedar/yoda.git
requires:
  - "Python:(?!osx)"
  - "Python-modules:(?!osx)"
  - "Python-system:(osx.*)"
  - ROOT
build_requires:
  - "autotools:(slc6|slc7)"
  - HepMC3
  - Python
prepend_path:
  PYTHONPATH: $YODA_ROOT/lib/python/site-packages
---
#!/bin/bash
#
# HepMC3 in build-requirements so that same ROOT as used 
# for HepMC3 is picked up.  This is to avoid 
# incompatibilities between different ROOT version
#
# Test building with 
#
#   alienv enter ./module 
#   export ALIBUILD_ARCH_PREFIX=el7-x86_64/Packages
#   export WORK_DIR=/cvmfs/alice.cern.ch
#   . ${PYTHONHOME}/etc/profile.d/init.sh
#   . ${HEPMC3_ROOT}/etc/profile.d/init.sh
#   aliBuild build \
#     --disable Python-modules,boost,defaults-release,CMake,HepMC3,ROOT \
#     --always-prefer-system \
#     --debug \
#     YODA 
# 
# Note that the '--disable' option prevents 
#
# - aliBuild from trying to build what we already have albeit not under
#   WORK_DIR/sw
# - aliBuild from importing depency package settings to be loaded and 
#   written to 'YODA/version/etc/profile.d/init.sh'
# - Variables to be set when making the module file
#
# I've not figured out a way to not build all dependencies, and there is 
# a lot, while still loading in the correct settings for build requirements
# and so on. As far as I can tell, it's not really supported by aliBuild - 
# surprise!
# 
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

[[ -e .missing_timestamps ]] && ./missing-timestamps.sh --apply || autoreconf -ivf

(
PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)')
PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'from sys import version_info as vi; print(f"{vi.major}.{vi.minor}")' )
if test "x$PYTHON_MODULES_ROOT" = "x" ; then 
    PMBIN=`echo $PATH | tr ':' '\n' | grep Python-modules | head -n 1` 
    if test x$PMBIN != x ; then 
        CYTHON=$PMBIN/cython
    else 
        CYTHON=`which cython`
    fi
else
    CYTHON=$PYTHON_MODULES_ROOT/bin/cython
fi

CYTHON_PATH="$(dirname -- "$CYTHON")"
if cython; then
    echo "Cython succesfully executed" 
else    
    stat=$?
    # Check if python executable is linked in cython bin folder 
    if [ $stat == 127 ]; then
        echo "python not found by cython, setting up link..." 
        ln -nsf "$PYTHON_EXECUTABLE" "$CYTHON_PATH/python3"
    else 
        echo "Issue in cython execution"
    fi       
fi    

case $ARCHITECTURE in
  osx*)
      ./configure --disable-silent-rules --enable-root --prefix="$INSTALLROOT"
  ;;
  *)
      ./configure --disable-silent-rules --enable-root --prefix="$INSTALLROOT" CYTHON="$CYTHON"
  ;;
esac
make -j$JOBS
make install

pushd $INSTALLROOT/lib

[[ -d python${PYTHON_VER} ]] && ln -s python${PYTHON_VER} python 
[[ ! -e python ]] && \
    echo "YODA env pb: NO PYTHON SYMLINK CREATED for python${PYTHON_VER} in: $(pwd -P)" && \
    exit 

popd  # get back from INSTALLROOT/lib

case $ARCHITECTURE in
    osx*)
        find $INSTALLROOT/lib/python/ -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
        find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
    ;;
esac
)

PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)')
if test "x$PYTHON_VERSION" != "x" && \
   test "x$PYTHON_REVISION" != "x" ; then 
    PYTHON_FULL_VERSION=${PYTHON_VERSION}-${PYTHON_REVISION}
else
    PYTHON_FULL_VERSION=$( echo $PYTHON_EXECUTABLE | sed -e 's|.*/Python/||' -e 's|/bin/.*||') 
fi

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

# alibuild-generate-module --bin --lib > "$MODULEFILE"0
# cat >> "$MODULEFILE"0 <<EoF
# prepend-path PYTHONPATH \$PKG_ROOT/lib/python/site-packages
# EoF

cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0					\\
            ${PYTHON_FULL_VERSION:+Python/$PYTHON_FULL_VERSION}	\\
            ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}

# Our environment
set YODA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
 
prepend-path PATH \$YODA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib64
set pythonpath [exec yoda-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
prepend-path PYTHONPATH \$YODA_ROOT/lib/python/site-packages
EoF
