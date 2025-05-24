package: Python
version: "%(tag_basename)s"
tag: v3.9.16
source: https://github.com/python/cpython
requires:
  - AliEn-Runtime:(?!.*ppc64)
  - FreeType
  - libpng
  - sqlite
  - "GCC-Toolchain:(?!osx)"
  - libffi
build_requires:
  - curl
  - alibuild-recipe-tools
env:
  SSL_CERT_FILE: "$(export PATH=$PYTHON_ROOT/bin:$PATH; export LD_LIBRARY_PATH=$PYTHON_ROOT/lib:$LD_LIBRARY_PATH; python -c \"import certifi; print(certifi.where())\")"
  PYTHONHOME: "$PYTHON_ROOT"
  PYTHONPATH: "$PYTHON_ROOT/lib/python/site-packages"
prefer_system: "(?!slc5|ubuntu)"
prefer_system_check: |
    case $ALIBUILD_ARCHITECTURE in
        osx*)
            # We need to include the python patch number because brew has it in the path
            python3 -c 'from sys import version_info; print(f"alibuild_system_replace: python-brew{version_info.major}.{version_info.minor}.{version_info.micro}")' ;;
        *)
            python3 -c 'from sys import version_info; print(f"alibuild_system_replace: python{version_info.major}.{version_info.minor}")'
        ;;
    esac
    python3 -c 'import sys; import sqlite3; sys.exit(1 if sys.version_info < (3, 9) or sys.version_info > (3, 14) else 0)' && python3 -m pip --help > /dev/null && printf '#include "pyconfig.h"' | cc -c $(python3-config --includes) -xc -o /dev/null -; if [ $? -ne 0 ]; then printf "Python, the Python development packages, and pip must be installed on your system.\nUsually those packages are called python, python-devel (or python-dev) and python-pip.\n"; exit 1; fi
prefer_system_replacement_specs:
  "python-brew3.*":
    version: "%(key)s"
    env:
        PYTHON_ROOT: $(brew --prefix python3)
        PYTHON_REVISION: ""
  "python3.*":
    version: "%(key)s"
    env:
        # Python is in path, so we need a dummy placeholder for PYTHON_ROOT
        # to avoid having /bin in the middle of the path.
        PYTHON_ROOT: "/dummy-python-folder"
        PYTHON_REVISION: ""
---
rsync -av --exclude '**/.git' $SOURCEDIR/ $BUILDDIR/

# According to cmsdist, this is required to pick up our own version
export LIBFFI_ROOT

# If the python installer finds another pip, it won't install the new one
export PATH=$(echo $PATH | awk -v RS=':' -v ORS=':' '!/python/ {print}' | sed 's/:$//')
unset PYTHONUSERBASE
unset PYTHONHOME
unset PYTHONPATH

# The only way to pass externals to Python
LDFLAGS=
CPPFLAGS=
for ext in $ALIEN_RUNTIME_ROOT $ZLIB_ROOT $FREETYPE_ROOT $LIBPNG_ROOT $SQLITE_ROOT $LIBFFI_ROOT; do
  LDFLAGS="$(find $ext -type d \( -name lib -o -name lib64 \) -exec echo -L\{\} \;) $LDFLAGS"
  CPPFLAGS="$(find $ext -type d -name include -exec echo -I\{\} \;) $CPPFLAGS"
done
export LDFLAGS=$(echo $LDFLAGS)
export CPPFLAGS=$(echo $CPPFLAGS)

# Check if OpenSSL and zlib are from AliEn
if [[ $ALIEN_RUNTIME_VERSION ]]; then
  OPENSSL_ROOT=${OPENSSL_ROOT:+$ALIEN_RUNTIME_ROOT}
  ZLIB_ROOT=${ZLIB_ROOT:+$ALIEN_RUNTIME_ROOT}
fi
case $ARCHITECTURE in
  osx*) [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl@3) ;;
esac

# Set own OpenSSL if appropriate
if [[ $OPENSSL_ROOT ]]; then
  export CPATH="$OPENSSL_ROOT/include:$OPENSSL_ROOT/include/openssl:$CPATH"
  export CPPFLAGS="-I$OPENSSL_ROOT/include -I$OPENSSL_ROOT/include/openssl $CPPFLAGS"
  export CFLAGS="-I$OPENSSL_ROOT/include -I$OPENSSL_ROOT/include/openssl $CFLAGS"
  cat >> Modules/Setup.dist <<EOF

SSL=$OPENSSL_ROOT
_ssl _ssl.c \
        -DUSE_SSL -I\$(SSL)/include -I\$(SSL)/include/openssl \
        -L\$(SSL)/lib -lssl -lcrypto

# Get rid of the dependency on libcrypt (which is going away in any case in python 3.13)
_crypt _cryptmodule.c # -lcrypt        # crypt(3); needs -lcrypt on some systems

*disabled*
_crypt
EOF
fi

LIBCRYPT_CFLAGS=-lunknown ac_cv_search_crypt=no ac_cv_search_crypt_r=no ./configure --prefix="$INSTALLROOT"  \
            ${OPENSSL_ROOT:+--with-openssl=$OPENSSL_ROOT} ${OPENSSL_ROOT:+--with-openssl-rpath=no} \
            --enable-shared          \
            --with-system-expat      \
            --with-ensurepip=install
make ${JOBS:+-j $JOBS}
make altinstall

# Patch long shebangs (by default max is 128 chars on Linux) and add pip(3)/python(3) symlinks
pushd "$INSTALLROOT/bin"
  sed -i.deleteme -e "1 s|^#!${INSTALLROOT}/bin/\(.*\)$|#!/usr/bin/env \1|" * || true
  rm -f *.deleteme
  PYTHON_BIN=$(for X in python*; do echo "$X"; done | grep -E '^python[0-9]+\.[0-9]+$' | head -n1)
  PIP_BIN=$(for X in pip*; do echo "$X"; done | grep -E '^pip[0-9]+\.[0-9]+$' | head -n1)
  PYTHON_CONFIG_BIN=$(for X in python*-config; do echo "$X"; done | grep -E '^python[0-9]+\.[0-9]+m?-config$' | head -n1)
  [[ -x python ]] || ln -nfs "$PYTHON_BIN" python
  [[ -x python3 ]] || ln -nfs "$PYTHON_BIN" python3
  [[ -x pip ]] || ln -nfs "$PIP_BIN" pip
  [[ -x pip3 ]] || ln -nfs "$PIP_BIN" pip3
  [[ -x python-config ]] || ln -nfs "$PYTHON_CONFIG_BIN" python-config
  [[ -x python3-config ]] || ln -nfs "$PYTHON_CONFIG_BIN" python3-config
popd

# Install Python SSL certificates right away
env PATH="$INSTALLROOT/bin:$PATH" \
    LD_LIBRARY_PATH="$INSTALLROOT/lib:$LD_LIBRARY_PATH" \
    PYTHONHOME="$INSTALLROOT" \
    python3 -m pip install 'certifi==2022.12.7'

# Uniform Python library path
pushd "$INSTALLROOT/lib"
  ln -nfs python* python
popd

# Remove useless stuff
rm -rvf "$INSTALLROOT"/share "$INSTALLROOT"/lib/python*/test
find "$INSTALLROOT"/lib/python* \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}' \;

# Get OpenSSL and zlib at runtime from AliEn-Runtime if appropriate
[[ $ALIEN_RUNTIME_REVISION ]] && unset OPENSSL_REVISION ZLIB_REVISION

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
setenv PYTHONHOME \$PKG_ROOT
prepend-path PYTHONPATH \$PKG_ROOT/lib/python/site-packages
if { [module-info mode load] } {
  setenv SSL_CERT_FILE  [exec \$PKG_ROOT/bin/python3 -c "import certifi; print(certifi.where())"]
}
if { [module-info mode remove] } {
  unsetenv SSL_CERT_FILE
}
EoF
