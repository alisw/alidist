package: SuperCHIC
version: "%(tag_basename)s%(defaults_upper)s"
tag: "alice/v2.04"
source: https://github.com/hcab14/SuperCHIC.git
requires:
 - lhapdf
build_requires:
 - curl
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e

rsync -a --exclude '**/.git' $SOURCEDIR/ ./

patch makefile <<EOF
8c8
< LHAPDFLIB = /usr/local/Cellar/lhapdf/6.1.5/lib
---
> LHAPDFLIB = ${LHAPDF_ROOT}/lib

EOF

mkdir -p obj

make ${JOBS+-j $JOBS}

# the makefile does not contain "install" -> manual installation
cp -R bin $INSTALLROOT

# install lhapdf sets MMHT2014*
lhapdf update

PDFSETS=`echo MMHT2014{lo68cl,lo_asmzsmallrange,nlo68cl,nlo68cl_nf{3,4},nlo68cl_nf4as5,nlo68clas118,nlo68clas118_nf{3,4},nlo68clas118_nf4as5,nlo_asmzlargerange,nlo_asmzsmallrange,nlo_asmzsmallrange_nf{3,4},nlo_mbrange_nf{3,4,5},nlo_mcrange_nf{3,4,5},nloas118_mbrange_nf{3,4,5},nloas118_mcrange_nf{3,4,5},nnlo68cl,nnlo68cl_nf{3,4},nnlo68cl_nf4as5,nnlo_asmzlargerange,nnlo_asmzsmallrange,nnlo_asmzsmallrange_nf{3,4},nnlo_mbrange_nf{3,4,5},nnlo_mcrange_nf{3,4,5}}`

lhapdf install $PDFSETS

# Check if PDF sets were really installed
for P in $PDFSETS; do
  ls ${LHAPDF_ROOT}/share/LHAPDF/$P
done

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
module load BASE/1.0 lhapdf/$LHAPDF_VERSION-$LHAPDF_REVISION
# Our environment
setenv SUPERCHIC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(SUPERCHIC_ROOT)/bin
EoF
