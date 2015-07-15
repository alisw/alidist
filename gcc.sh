package: GCC
version: 4.9.3
source: https://github.com/dberzano/gcc 
tag: alice/4.9.3
---
#!/bin/bash -e

# http://stackoverflow.com/questions/9450394/how-to-install-gcc-from-scratch-with-gmp-mpfr-mpc-elf-without-shared-librari

case $ARCHITECTURE in
  osx*) AdditionalLanguages=',objc,obj-c++' ;;
esac

cd "$SOURCEDIR"

# TODO: maybe, have them in aliBuild?
git reset --hard HEAD
git clean -f -d
git clean -fX

# Use system's autotools
for External in mpfr mpc gmp isl cloog ; do
  pushd $External
  autoreconf -fi
  popd
done

# Not necessary: externals imported in repo
#./contrib/download_prerequisites

"$SOURCEDIR"/configure \
  --prefix="$INSTALLROOT" \
  --enable-languages="c,c++,fortran${AdditionalLanguages}"

make ${JOBS+-j $JOBS}
make ${JOBS+-j $JOBS} install
