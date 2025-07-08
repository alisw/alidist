package: GMP
version: v6.2.1
tag: v6.2.1
source: https://github.com/alisw/GMP.git
requires:
  - "GCC-Toolchain:(?!osx)"
---
#!/bin/sh
case $ARCHITECTURE in
  osx*) MARCH="" ;;
  *x86-64) MARCH="core2" ;;
  *) MARCH= ;;
esac

# temporary fix C23 (since gcc 15) compatibility
sed -i.orig 's/void g(){}/void g(int p1,t1 const* p2,t1 p3,t2 p4,t1 const* p5,int p6){}/' "$SOURCEDIR/acinclude.m4"
sed -i.orig 's/void g(){}/void g(int p1,t1 const* p2,t1 p3,t2 p4,t1 const* p5,int p6){}/' "$SOURCEDIR/configure"

case $ARCHITECTURE in
  osx*)
      $SOURCEDIR/configure --prefix=$INSTALLROOT \
			   --enable-cxx \
			   --disable-static \
			   --enable-shared \
			   ${MARCH:+--build=$MARCH --host=$MARCH} \
			   --with-pic
  ;;
  *)
      $SOURCEDIR/configure --prefix=$INSTALLROOT \
			   --enable-cxx \
			   --enable-static \
			   --disable-shared \
			   ${MARCH:+--build=$MARCH --host=$MARCH} \
			   --with-pic
  ;;
esac

make ${JOBS+-j $JOBS} MAKEINFO=:
make install MAKEINFO=:

rm -f $INSTALLROOT/lib/*.la

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set GMP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv GMP_ROOT \$GMP_ROOT
prepend-path LD_LIBRARY_PATH \$GMP_ROOT/lib
EoF
