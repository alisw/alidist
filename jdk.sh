package: JDK
version: "10.0.1"
build_requires:
  - curl
prefer_system: .*
prefer_system_check: |
  X=$(mktemp -d); cd $X && printf "public class verAliBuild { public static void main(String[] args) { if (Integer.parseInt((System.getProperty(\"java.version\")+\".\").split(\"\\\\\.\")[0]) < 10) System.exit(42); } }" > verAliBuild.java && javac verAliBuild.java && java verAliBuild && rm -rf $X
---
#!/bin/bash -e

[[ $(uname) != Linux ]] && { echo "Works on Linux only"; false; }

URL="http://download.oracle.com/otn-pub/java/jdk/10.0.1+10/fb4372174a714e6b8c52526dc134031e/jdk-10.0.1_linux-x64_bin.tar.gz"
mkdir -p "$INSTALLROOT"
curl -b "oraclelicense=a" -L $URL | tar --strip-components 1 -C "$INSTALLROOT" -xvvz

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
module load BASE/1.0
# Our environment
set JDK_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$JDK_ROOT/bin
EoF
