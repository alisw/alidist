package: JDK
version: "21.0.6"
build_requires:
  - curl
prefer_system: .*
prefer_system_check: |
  [[ $(uname) == Darwin ]] && /usr/libexec/java_home || exit 1; X=$(mktemp -d); cd $X && printf "public class verAliBuild { public static void main(String[] args) { if (Integer.parseInt((System.getProperty(\"java.version\")+\".\").split(\"\\\\\.\")[0]) < 10) System.exit(42); } }" > verAliBuild.java && javac verAliBuild.java && java verAliBuild && rm -rf $X
env:
  JAVA_HOME: "$JDK_ROOT/$(cd $JDK_ROOT; ls -1d jdk*/Contents/Home)"
prepend_path:
  PATH: "$JAVA_HOME/bin"
---
#!/bin/bash -e

JDK_PLATFORM=linux
URL="https://cdn.azul.com/zulu/bin/zulu21.40.17-ca-jdk21.0.6-linux_x64.tar.gz"

mkdir -p "$INSTALLROOT"
curl -L $URL | tar --strip-components 1 -C "$INSTALLROOT" -xvvz

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
set JAVA_HOME \$::env(BASEDIR)/$PKGNAME/\$version${JAVA_HOME_SUBDIR}
setenv JAVA_HOME \$JAVA_HOME
prepend-path PATH \$JAVA_HOME/bin
EoF
