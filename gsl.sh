package: GSL
version: "v2.8"
tag: "v2.8"
source: https://github.com/alisw/gsl
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included)\"\n#endif\nint main(){}" | cc -xc - -I$(brew --prefix gsl)/include  -c -o /dev/null
---
#!/bin/bash -e
rsync -a --chmod=ug=rwX --exclude .git --delete-excluded $SOURCEDIR/ $BUILDDIR/
# Do not build documentation
sed -i.bak -e "s/doc//" Makefile.am
sed -i.bak -e "s|doc/Makefile||" configure.ac
autoreconf -f -v -i
./configure --prefix="$INSTALLROOT" \
            --enable-maintainer-mode
make ${JOBS:+-j$JOBS}
make ${JOBS:+-j$JOBS} install
rm -fv $INSTALLROOT/lib/*.la
# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
