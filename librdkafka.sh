package: librdkafka
version: "%(tag_basename)s"
tag: v2.3.0
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
  - CMake
source: https://github.com/edenhill/librdkafka
---

rsync -a --delete --exclude "**/.git" "$SOURCEDIR/" .

# cmake in rdfkafka links against ssl even when disabled, so we need to use configure, which is also recommended by librdkafka devs.
./configure --prefix="$INSTALLROOT" --disable-ssl --disable-gssapi --disable-curl

make
make install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > "etc/modulefiles/$PKGNAME"
cat >> "etc/modulefiles/$PKGNAME" <<EoF
EoF
mkdir -p "$INSTALLROOT/etc/modulefiles" && rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"
