package: GCC
version: 4.9.3
source: https://github.com/dberzano/gcc 
tag: alice/4.9.3
prepend_path:
  "LD_LIBRARY_PATH": "$GCC_ROOT/lib64"
  "DYLD_LIBRARY_PATH": "$GCC_ROOT/lib64"
---
#!/bin/bash -e

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
make install

# GCC creates c++, but not cc
ln -nfs gcc "$INSTALLROOT"/bin/cc
