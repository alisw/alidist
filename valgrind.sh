package: valgrind
version: "3.18.1"
tag: VALGRIND_3_18_1
source: git://sourceware.org/git/valgrind.git
build_requires:
  - autotools
  - GCC-Toolchain
  - alibuild-recipe-tools
---

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
echo test
CONF_OPTS="--enable-only64bit"
case $ARCHITECTURE in
  osx*)
    CFLAGS="-D__private_extern__=extern"
    ;;
esac

./autogen.sh
./configure --prefix=$INSTALLROOT --without-mpicc --disable-static ${CONF_OPTS}
make -j 20
make install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
prepend-path VALGRIND_LIB \$PKG_ROOT/libexec/valgrind
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
