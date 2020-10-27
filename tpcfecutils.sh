package: TpcFecUtils
version: "%(tag_basename)s"
tag: v0.1.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - Python
  - ReadoutCard
  - LLA
build_requires:
  - CMake
source: https://gitlab+deploy-token-1303:ivjQdcMRX9qpxdv4RCcM@gitlab.cern.ch/alice-tpc-upgrade/alice-tpc-fec-utils.git
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

# Handle submodule business
pushd $SOURCEDIR
git config submodule.submodules/gbt-hdlc.url \
  https://gitlab+deploy-token-1305:2SyHnx1Tk8Rc8dY5AV9s@gitlab.cern.ch/alice-tpc-upgrade/gbt-hdlc-light.git
git submodule update --init
popd

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

# Enforce no warning code in the PR checker
if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                  \
      -DBUILD_FOR_READOUT_CARD=CRU                \
      -DBUILD_FOR_CRU_HDLC_CORE=CERN_ME           \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT         \
      ${BOOST_REVISION:+-DBoost_ROOT=$BOOST_ROOT} \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

# Reduce number of jobs if invoked by Jenkins
if [ ! "X$JENKINS_HOME" = X ]; then
  JOBS=1
fi
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0                                                \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION} \\
            ReadoutCard/$READOUTCARD_VERSION-$READOUTCARD_REVISION  \\
            ${LLA_REVISION:+LLA/$LLA_VERSION-$LLA_REVISION}

# Our environment
set TPCFECUTILS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv TPCFECUTILS_ROOT \$TPCFECUTILS_ROOT
prepend-path PATH \$TPCFECUTILS_ROOT/bin
prepend-path LD_LIBRARY_PATH \$TPCFECUTILS_ROOT/lib
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
