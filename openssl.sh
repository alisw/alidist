package: OpenSSL
version: v1.1.1m
tag: OpenSSL_1_1_1m
source: https://github.com/openssl/openssl
prefer_system: (?!slc5|slc6)
prefer_system_check: |
  #!/bin/bash -e
  case $(uname) in
    Darwin) prefix=$(brew --prefix openssl@3); [ -d "$prefix" ] ;;
    *) prefix= ;;
  esac
  cc -x c - ${prefix:+"-I$prefix/include"} -c -o /dev/null <<\EOF
  #include <openssl/bio.h>
  #include <openssl/opensslv.h>
  #if OPENSSL_VERSION_NUMBER < 0x10101000L
  #error "System's OpenSSL cannot be used: we need OpenSSL >= 1.1.1 for the Python ssl module. We are going to compile our own version."
  #endif
  int main() { }
  EOF
build_requires:
  - zlib
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
prepend_path:
  PKG_CONFIG_PATH: "$OPENSSL_ROOT/lib/pkgconfig"
---
#!/bin/bash -e

rsync -av --delete --exclude="**/.git" "$SOURCEDIR/" .
case ${PKG_VERSION} in
  v1.1*)
    OPTS=""
    OPENSSLDIRPREFIX="" ;;
  *)
    OPTS="no-krb5"
    OPENSSLDIRPREFIX="etc/ssl"
  ;;
esac

./config --prefix="$INSTALLROOT"                   \
         --openssldir="$INSTALLROOT/$OPENSSLDIRPREFIX"       \
         --libdir=lib                              \
         zlib                                      \
         no-idea                                   \
         no-mdc2                                   \
         no-rc5                                    \
         no-asm                                    \
         ${OPTS}                                   \
         shared                                    \
         -fno-strict-aliasing                      \
         -L"$INSTALLROOT/lib"                      \
         -Wa,--noexecstack
make depend
make  # don't ever try to build in multicore
make install_sw # no not install man pages

# Remove static libraries and pkgconfig
rm -rf "$INSTALLROOT"/lib/*.a

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"

mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin > "$MODULEFILE"
cat << EOF >> "$MODULEFILE"
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
mkdir -p "$INSTALLROOT/etc/modulefiles"
rsync -a --delete  "$MODULEDIR/" "$INSTALLROOT/etc/modulefiles"
