package: GSL
version: "v1.16%(defaults_upper)s"
source: https://github.com/alisw/gsl
tag: "release-1-16"
build_requires:
  - autotools
requires:
  - "GCC-Toolchain:(?!osx|slc5)"
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"gsl/gsl_version.h\"\n# if (GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION < 116)\n#error \"Cannot use system's gsl.\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null
---
#!/bin/bash -e
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
# Do not build documentation
perl -p -i -e "s/doc//" Makefile.am
perl -p -i -e "s|doc/Makefile||" configure.ac
autoreconf -f -v -i
./configure --prefix="$INSTALLROOT" \
            --enable-maintainer-mode
make ${JOBS:+-j$JOBS}
make ${JOBS:+-j$JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv GSL_BASEDIR \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(GSL_BASEDIR)/lib
prepend-path PATH \$::env(GSL_BASEDIR)/bin
EoF
