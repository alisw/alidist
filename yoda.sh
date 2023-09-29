package: YODA
version: "%(tag_basename)s"
tag: "yoda-1.9.7"
source: https://gitlab.com/hepcedar/yoda
requires:
  - boost
  - "Python:(?!osx)"
  - "Python-modules:(?!osx)"
  - "Python-system:(osx.*)"
  - ROOT
build_requires:
  - "autotools:(slc6|slc7)"
prepend_path:
  # See below at build time the management towards generic path .../lib/python/site-packages
  PYTHONPATH: $YODA_ROOT/lib/python/site-packages
---
#!/bin/bash

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

[[ -e .missing_timestamps ]] && ./missing-timestamps.sh --apply || autoreconf -ivf

(

PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)')PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )


unset PYTHON_VERSION

case $ARCHITECTURE in
  osx*)
      ./configure --disable-silent-rules --enable-root --prefix="$INSTALLROOT"
  ;;
  *)
      ./configure --disable-silent-rules --enable-root --prefix="$INSTALLROOT" CYTHON="$PYTHON_MODULES_ROOT/share/python-modules/bin/cython"
  ;;
esac
make -j$JOBS
make install


# Manage after compilation+install the path towards python site-package 
#   i.e. we aim at adapting from hardcoded "$YODA_ROOT/lib/python3.9/site-packages" to a generic symlink "$YODA_ROOT/lib/python/site-packages"
#   inspired from recipe alidist/xrootd.sh
#   (What we do here, at built time, is needed for "prepend_path PYTHONPATH" above in the recipe header;
#   the prepend_path occurs _after_ the built is completed.)

pushd ${INSTALLROOT}/lib
# Hypothesis : path towards lib is expected as $YODA_ROOT/lib/ (and
# nothing like $YODA_ROOT/lib64 or $YODA_ROOT/local/lib/ ...)  NOTE :
# there could be cases where python bindings are installed as relative
# to INSTALLROOT : case not met so far for YODA (slc, ubuntu) ...

if [[ -d python${PYTHON_VER} ]]; then
    # symlink from ${INSTALLROOT}/lib/python3.9 to ${INSTALLROOT}/lib/python
    ln -s python${PYTHON_VER} python 
fi

if [[ ! -e python ]] && echo "YODA env pb: NO PYTHON SYMLINK CREATED for python${PYTHON_VER} in: $(pwd -P)"; then 
    exit 
fi    

popd  # get back from INSTALLROOT/lib

case $ARCHITECTURE in
    osx*)
        find $INSTALLROOT/lib/python/ -name "*.so" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
        find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
    ;;
esac


)






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
module load BASE/1.0                                                    \\
            boost/$BOOST_VERSION-$BOOST_REVISION                        \\
            ${PYTHON_REVISION:+Python/$PYTHON_VERSION-$PYTHON_REVISION} \\
            ROOT/$ROOT_VERSION-$ROOT_REVISION

# Our environment
set YODA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version

prepend-path PATH \$YODA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib
prepend-path LD_LIBRARY_PATH \$YODA_ROOT/lib64
set pythonpath [exec yoda-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
EoF
