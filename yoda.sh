package: YODA
version: "%(tag_basename)s"
tag: "v1.9.5"
source: https://github.com/alisw/yoda
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

PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)') 
    # python3 here should come from our own Python package ("requires"), see alidist/python.sh
    # The command will return sthg like "python3.9"
PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )
    # The command will return sthg like "3.9"


unset PYTHON_VERSION
    # _Question 2_ :
    # YODA configure needs at least 2 python-related environment variables :
    #   From YODA/configure -help :
    #   PYTHON_VERSION
    #          The installed Python version to use, for example '2.3'. This
    #          string will be appended to the Python interpreter canonical
    #          name.
    #   PYTHON      the Python interpreter


    # After requirement of python module, python installation should point to our custom python (see alidist/python.sh)
    # from there, it seems to lead to PYTHON_VERSION="v3.9.12",
    # However it needs here to become PYTHON_VERSION="3.9" for yoda configure, i.e. PYTHON_VERSION is an env variable used by the configure file
    # See yoda/configure.ac

    # The surprise is that everything seems to be managed automagically when simply having here in the recipe "unset PYTHON_VERSION"

    # 1. Log with require python + _NO_ "unset PYTHON_VERSION" :
    #   ...
    #   2022-08-19@18:34:36:DEBUG:YODA:YODA:v1.9.5: checking for pythonv3.9.12... no
    #   2022-08-19@18:34:36:DEBUG:YODA:YODA:v1.9.5: configure: error: Cannot find pythonv3.9.12 in your system path
    #   ...
    # The command to be tested for YODA stems from YODA/configure file (https://github.com/alisw/yoda/blob/v1.9.5/configure) :
    # l.17138   set dummy python$PYTHON_VERSION; ac_word=$2

    # 2. Log with require python + "unset PYTHON_VERSION" :
    #   ...
    #   2022-08-19@18:24:50:DEBUG:YODA:YODA:v1.9.5: checking for python version... 3.9
    #   ...
    # i.e. smooth and properly set up
    #       The key seems to be about the "python" command ($PYTHON) to be looked up,
    #       if we point towards the right python binary - our python installation - from there the configure seems to find its way on its own
    # i.e. there is apparently _N0_ explicit need to do the following chain :
    #     PYTHON_EXECUTABLE=$(/usr/bin/env python3 -c 'import sys; print(sys.executable)') # python3 here should come from our own Python package, see alidist/python.sh
    #     PYTHON_VER=$( ${PYTHON_EXECUTABLE} -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )
    #     PYTHON="python${PYTHON_VER}" # PYTHON var is needed for the YODA configure
    #    # PYTHON_VERSION=$PYTHON_VER # PYTHON_VERSION var is needed for the YODA configure; for some reason (?), the needed variable seems to be properly set up finally without doing anything further here.


case $ARCHITECTURE in
  osx*)
      ./configure --disable-silent-rules --enable-root --prefix="$INSTALLROOT"
  ;;
  *)
      ./configure --disable-silent-rules --enable-root --prefix="$INSTALLROOT" CYTHON="$PYTHON_MODULES_ROOT/share/python-modules/bin/cython"
      # --enable-root is needed to build/access e.g. yoda2root and root2yoda conversion scripts between YODA and ROOT formats (e.g. ROOT::TH1D <-> YODA::Histo1D)
      # PyROOT compatibility is enabled by default in YODA (v1.9.5), PyROOT is built by default in our ROOT version.
      # root-config is needed behind the scene here to configure properly the ROOT environment.

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
# Hypothesis : path towards lib is expected as $YODA_ROOT/lib/ (and nothing like $YODA_ROOT/lib64 or $YODA_ROOT/local/lib/ ...)
# NOTE : there could be cases where python bindings are installed as relative to INSTALLROOT : case not met so far for YODA (slc, ubuntu) ...

if [[ -d python${PYTHON_VER} ]]; then
    ln -s python${PYTHON_VER} python # symlink from ${INSTALLROOT}/lib/python3.9 to ${INSTALLROOT}/lib/python
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
