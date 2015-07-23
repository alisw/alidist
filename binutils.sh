package: Binutils
version: "2.25"
source: git://sourceware.org/git/binutils-gdb.git
tag: binutils-2_25
---
#!/bin/bash -e

cd "$SOURCEDIR"
git reset --hard HEAD
git clean -f -d
git clean -fX

cd "$BUILDDIR"
"$SOURCEDIR"/configure --prefix="$INSTALLROOT"

make ${JOBS+-j $JOBS}
make install
