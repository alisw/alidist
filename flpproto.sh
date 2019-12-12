package: flpproto
version: "%(tag_basename)s"
tag: v0.9.2
requires:
  - Common-O2
  - Monitoring
  - Configuration
  - O2
  - "GCC-Toolchain:(?!osx)"
  - InfoLogger
  - ReadoutCard
  - Readout
  - qcg
  - QualityControl
  - ALF
source: https://github.com/AliceO2Group/FlpPrototype
valid_defaults:
  - o2
  - o2-dataflow
  - o2-dev-fairroot
  - alo
  - o2-prod
  - o2-ninja
incremental_recipe: |
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

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
module load BASE/1.0                                                      \\
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} \\
            O2/$O2_VERSION-$O2_REVISION                                   \\
            Monitoring/$MONITORING_VERSION-$MONITORING_REVISION           \\
            Configuration/$CONFIGURATION_VERSION-$CONFIGURATION_REVISION  \\
            Common-O2/$COMMON_O2_VERSION-$COMMON_O2_REVISION              \\
            InfoLogger/$INFOLOGGER_VERSION-$INFOLOGGER_REVISION           \\
            ReadoutCard/$READOUTCARD_VERSION-$READOUTCARD_REVISION        \\
            Readout/$READOUT_VERSION-$READOUT_REVISION                    \\
            FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION                 \\
            QualityControl/$QUALITYCONTROL_VERSION-$QUALITYCONTROL_REVISION

# Our environment
setenv FLPPROTO_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles

