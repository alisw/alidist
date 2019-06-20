package: Alice-GRID-Utils
version: "%(tag_basename)s"
tag: "0.0.0"
source: https://gitlab.cern.ch/nhardi/alice-grid-utils.git
---
#!/bin/bash -e

DST="$INSTALLROOT/include"
mkdir -p "$DST"
cp -v $SOURCEDIR/*.h "$DST/"
