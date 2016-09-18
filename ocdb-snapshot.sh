package: OCDB-Snapshot
version: "%(year)s-%(month)s-%(day)s_TEST"
build_requires:
  - AliEn-Runtime
env:
  OCDB_SNAPSHOT: "$OCDB_SNAPSHOT_ROOT/etc/ocdb_snapshot.txt"
---
#!/bin/bash -e
YEAR=$(TZ='Europe/Zurich' date +%Y)
DETECTORS=$(alien_ls /alice/data/$YEAR/OCDB)
[[ "$DETECTORS" ]] || { echo "FATAL: Cannot get detectors for /alice/data/$YEAR/OCDB"; false; }
mkdir -p $INSTALLROOT/etc
for DET in $DETECTORS; do
  echo "Listing /alice/data/$YEAR/OCDB/$DET..."
  alien_find /alice/data/$YEAR/OCDB/$DET %.root | grep ^/alice/data/ >> $INSTALLROOT/etc/ocdb_snapshot.txt || \
    { echo "FATAL: No entries found under /alice/data/$YEAR/OCDB/$DET"; false; }
done
echo "Found $(wc -l $INSTALLROOT/etc/ocdb_snapshot.txt | awk '{ print $1 }') total entries"

# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
setenv OCDB_SNAPSHOT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv OCDB_SNAPSHOT \$::env(OCDB_SNAPSHOT_ROOT)/etc/ocdb_snapshot.txt
setenv OCDB_SNAPSHOT_VERSION $PKGVERSION-@@PKGREVISION@$PKGHASH@@
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
