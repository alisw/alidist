package: rocm
version: "5.3"
build_requires:
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/sh

cd $SOURCEDIR
curl -fsSL https://s3.cern.ch/swift/v1/alibuild-repo/slc8-gpu-builder-reqs/amdappsdk.tar.bz2 | tar -xjv
./AMD-APP-SDK-v3.0.130.136-GA-linux64.sh --noexec --target $INSTALLROOT
rm -fr $INSTALLROOT/{bin,lib}/x86
rm -fr $INSTALLROOT/{samples,docs}
echo $INSTALLROOT/lib/x86_64/sdk/libamdocl64.so > $INSTALLROOT/etc/OpenCL/vendors/amdocl64.icd

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
module load BASE/1.0
# Our environment
set BASEDIR \$::env(BASEDIR)
setenv OCL_ICD_FILENAMES \$BASEDIR/$PKGNAME/\$version/etc/OpenCL/vendors/amdocl64.icd
setenv OCL_ICD_VENDORS \$BASEDIR/$PKGNAME/\$version/etc/OpenCL/vendors/
setenv OPENCL_VENDOR_PATH \$BASEDIR/$PKGNAME/\$version/etc/OpenCL/vendors/
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib/x86_64
prepend-path PATH \$BASEDIR/$PKGNAME/\$version/bin/x86_64
EoF
