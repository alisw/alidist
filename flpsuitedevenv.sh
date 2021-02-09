package: FLPSuiteDevEnv
version: "1.0.0"
tag: "FLPSuiteDevEnv-1.0.0"
requires:
  - CMake
  - O2-customization
  - alibuild-recipe-tools
  - ms_gsl
  - RapidJSON
  - GMP
  - MPFR
  - defaults-release
  - abseil
  - freeglut-devel
  - OpenSSL
  - abseil
valid_defaults:
  - o2
  - o2-dataflow
---

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"

mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat << EOF >> etc/modulefiles/$PKGNAME
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
