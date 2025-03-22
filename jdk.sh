package: JDK
version: "17.0.14"
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
[[ $ARCHITECTURE != osx* ]] || JDK_PLATFORM=osx

if [[ $JDK_PLATFORM == osx ]]; then
  URL="https://cdn.azul.com/zulu/bin/zulu17.56.15-ca-jdk17.0.14-macosx_x64.tar.gz"
else
  URL="https://cdn.azul.com/zulu/bin/zulu17.56.15-ca-jdk17.0.14-linux_x64.tar.gz"  
fi

mkdir -p "$INSTALLROOT"
curl -L $URL | tar --strip-components 1 -C "$INSTALLROOT" -xvvz

if [[ $JDK_PLATFORM == osx ]]; then
  JAVA_HOME_SUBDIR=$(cd $INSTALLROOT && find . -type d -name Home -mindepth 3 -maxdepth 3)
  JAVA_HOME_SUBDIR=/${JAVA_HOME_SUBDIR:2}
  [[ $JAVA_HOME_SUBDIR ]] || exit 1
fi

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
