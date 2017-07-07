package: flpproto
requires:
  - Monitoring
  - Configuration
  - O2
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
source: https://github.com/AliceO2Group/FlpPrototype
version: "%(tag_basename)s"
tag: v0.4.4
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

---
#!/bin/sh

# Making sure people do not have SIMPATH set when they build fairroot.
# Unfortunately SIMPATH seems to be hardcoded in a bunch of places in
# fairroot, so this really should be cleaned up in FairRoot itself for
# maximum safety.
unset SIMPATH

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=`brew --prefix zeromq`
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=`brew --prefix protobuf`
    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac

cmake $SOURCEDIR                                              \
    -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                     \
    -DCMAKE_MODULE_PATH="$SOURCEDIR/cmake/modules;$FAIRROOT_ROOT/share/fairbase/cmake/modules;$FAIRROOT_ROOT/share/fairbase/cmake/modules_old" \
    ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}     \
    -DFAIRROOTPATH=$FAIRROOT_ROOT \
    -DFairRoot_DIR=$FAIRROOT_ROOT                               \
    -DROOTSYS=$ROOTSYS \
    ${Configuration_ROOT:+-DConfiguration_ROOT=$Configuration_ROOT} \
    ${Monitoring_ROOT:+-DMonitoring_ROOT=$Monitoring_ROOT}

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
module load BASE/1.0                                                                            \\
            ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            O2/$O2_VERSION-$O2_REVISION                                                         \\
            Monitoring/$MONITORING_VERSION-$MONITORING_REVISION                                 \\
            Configuration/$CONFIGURATION_VERSION-$CONFIGURATION_REVISION                        

# Our environment
setenv FLPPROTO_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
