package: localccdb
version: "%(tag_basename)s"
tag: "1.0.26"
requires:
  - JDK
build_requires:
  - curl
---
#!/bin/bash -e

URL="http://alimonitor.cern.ch/download/local-$PKGVERSION.jar"

curl -kLo local.jar "$URL"

mkdir $INSTALLROOT/bin
cp local.jar $INSTALLROOT/bin

# Launch executable
STARTEXECUTABLE="$INSTALLROOT/bin/startccdb"
cat > "$STARTEXECUTABLE" <<EOF
#! /bin/bash

function printHelp() {
    echo "Usage: startccdb [OPTION]"
    echo ""   
    echo "OPTIONS:"
    echo " . -r/--repository: Repository where to store the data (mandatory)"
    echo " . -p/--port: HTTP port of the CCDB"
}

REPOSITORY=
PORT=8080

while [[ \$# -gt 0 ]]; do
  case "\$1" in
    --port|-p) PORT="\$2"; shift 2 ;;
    --repository|-r) REPOSITORY="\$2"; shift 2 ;;
    --help|help) printHelp; exit 0 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [ "x\$REPOSITORY" == "x" ]; then
   echo "Repository for data needs to be specified"
   printHelp
   exit 1
fi

export TOMCAT_PORT=\$PORT
export FILE_REPOSITORY_LOCATION=\$REPOSITORY

java -jar \$LOCALCCDB_ROOT/bin/local.jar
EOF
chmod +x $STARTEXECUTABLE

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
module load BASE/1.0 ${JDK_REVISION:+JDK/$JDK_VERSION-$JDK_REVISION}
# Our environment
set LOCALCCDB_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv LOCALCCDB_ROOT \$LOCALCCDB_ROOT
prepend-path PATH \$LOCALCCDB_ROOT/bin
EoF
