package: JDK
version: "10.0.1"
build_requires:
 - curl

prefer_system: "(?!osx)"
prefer_system_check: |
    javac &> /dev/null && case `javac --version | awk '{print $2}'` in [0-9].*|10.0.0) exit 1 ;; esac
---
#!/bin/bash -e

[[ $(uname) != Linux ]] && { echo "Works on Linux only"; false; }

ZIP_NAME="jdk-${PKGVERSION}_linux-x64_bin.tar.gz"
URL="http://download.oracle.com/otn-pub/java/jdk/10.0.1+10/fb4372174a714e6b8c52526dc134031e/$ZIP_NAME"

mkdir -p "$INSTALLROOT"
curl -b "oraclelicense=a" -L $URL | tar --strip-components 1 -C "$INSTALLROOT" -xvz 

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
