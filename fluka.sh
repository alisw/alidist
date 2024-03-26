package: FLUKA
version: "%(tag_basename)s"
tag: "4-1.1-vmc5"
source: https://gitlab.cern.ch/ALICEDevOps/FLUKA.git
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
env:
  FLUPRO: "$FLUKA_ROOT/lib"
  FC: "gfortran"
prepend_path:
  PATH: "$FLUKA_ROOT/bin"
---
export FLUPRO=$PWD
export FC=gfortran

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ "$BUILDDIR"

FVERSION=`gfortran --version | grep -i fortran | sed -e 's/.* //' | cut -d. -f1`
if [ $FVERSION -ge 10 ]; then
    echo "Fortran version $FVERSION"
    # Redefine FC to contain the compiler, -fallow-argument-mismatch and the additional FFLAGS from FLUKA/src/config.mk
    case $ARCHITECTURE in
	osx_arm64)
	    make FC="gfortran -fallow-argument-mismatch -Wall -Waggregate-return -Wcast-align -Wline-truncation -Wno-conversion -Wno-integer-division -Wno-tabs -Wno-unused-dummy-argument -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable -Wsystem-headers -Wuninitialized -Wunused-label -mtune=generic -fPIC -fexpensive-optimizations -funroll-loops -fstrength-reduce -fno-automatic -finit-local-zero -ffixed-form -fbackslash -funderscoring -fd-lines-as-code -frecord-marker=4 -fbacktrace -frange-check -fbounds-check -fdump-core -ftrapping-math -ffpe-trap=invalid,zero,overflow" ${JOBS:+-j$JOBS}
	    ;;
	*)
	    make FC="gfortran -fallow-argument-mismatch -Wall -Waggregate-return -Wcast-align -Wline-truncation -Wno-conversion -Wno-integer-division -Wno-tabs -Wno-unused-dummy-argument -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable -Wsystem-headers -Wuninitialized -Wunused-label -mtune=generic -msse2 -mfpmath=sse -fPIC -fexpensive-optimizations -funroll-loops -fstrength-reduce -fno-automatic -finit-local-zero -ffixed-form -fbackslash -funderscoring -fd-lines-as-code -frecord-marker=4 -fbacktrace -frange-check -fbounds-check -fdump-core -ftrapping-math -ffpe-trap=invalid,zero,overflow" ${JOBS:+-j$JOBS}
	    ;;
    esac
else
    make ${JOBS:+-j$JOBS}
fi

mkdir -p $INSTALLROOT
cp -rf $BUILDDIR/bin $BUILDDIR/lib $BUILDDIR/include $BUILDDIR/data $INSTALLROOT/

#ModuleFile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
cat >> $INSTALLROOT/etc/modulefiles/$PKGNAME <<EoF
# Our environment
set FLUKA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FLUPRO \$::env(BASEDIR)/$PKGNAME/\$version/lib
prepend-path PATH \$FLUKA_ROOT/bin
EoF
