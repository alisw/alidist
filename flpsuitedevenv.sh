package: FLPSuiteDevEnv
version: "1.0.0"
tag: "FLPSuiteDevEnv-1.0.0"
requires:
  - abseil
  - alibuild-recipe-tools
  - autotools
  - bz2
  - capstone
  - CMake
  - defaults-release
  - double-conversion
  - flatbuffers
  - FreeType
  - GMP
  - googlebenchmark
  - googletest
  - libffi
  - MPFR
  - ms_gsl
  - O2-customization
  - OpenSSL
  - Python-modules-list
  - RapidJSON
  - re2
  - sqlite
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

# External RPM dependencies
cat > $INSTALLROOT/.rpm-extra-deps <<EoF
freeglut-devel
EoF
