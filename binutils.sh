package: Binutils
version: "2.25"
source: git://sourceware.org/git/binutils-gdb.git
tag: binutils-2_25
---
#!/bin/bash -e

"$SOURCEDIR"/configure --prefix="$INSTALLROOT"

make ${JOBS+-j $JOBS}
make ${JOBS+-j $JOBS} install
