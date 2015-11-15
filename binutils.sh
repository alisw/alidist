package: Binutils
version: "2.25"
source: https://github.com/bminor/binutils-gdb
tag: binutils-2_25
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./
./configure --prefix="$INSTALLROOT"
make ${JOBS+-j $JOBS}
make install
