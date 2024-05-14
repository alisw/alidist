package: TpcFecUtils
version: "%(tag_basename)s"
tag: v0.4.1
requires:
  - "GCC-Toolchain:(?!osx)"
  - boost
  - "Python:(slc.*)"
  - "Python-system:(?!slc)"
  - ReadoutCard
  - LLA
build_requires:
  - CMake
source: https://gitlab.cern.ch/ALICEPrivateExternals/alice-tpc-fec-utils.git
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

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

make ${JOBS+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
