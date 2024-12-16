package: boost
version: v1.83.0-alice2
tag: v1.83.0-alice2
source: https://github.com/alisw/boost.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - Python-modules
  - libpng
  - zlib
build_requires:
  - lzma
  - bz2
  - alibuild-recipe-tools
prepend_path:
  ROOT_INCLUDE_PATH: "$BOOST_ROOT/include"
---
BOOST_PYTHON=
BOOST_CXXFLAGS=
if [[ $ARCHITECTURE != osx* && $PYTHON_MODULES_VERSION ]]; then
  # Enable boost_python on platforms other than macOS
  BOOST_PYTHON=1
  if [[ $PYTHON_VERSION ]]; then
    # Our Python. We need to pass the appropriate flags to boost for the includes
    BOOST_CXXFLAGS="$(python3-config --includes)"
  else
    # Using system's Python. We want to make sure `python-config` is available in $PATH and points
    # to the Python 3 version. Note that a symlink will not work due to the automatic prefix
    # calculation of the python-config script. Our own Python does not require tricks
    if ! type python3-config &> /dev/null; then
      echo "FATAL: cannot find python3-config in your \$PATH. Cannot enable boost_python"
      exit 1
    fi
    mkdir fake_bin
    cat > fake_bin/python-config <<\EOF
#!/bin/bash
exec python3-config "$@"
EOF
    chmod +x fake_bin/python-config
    ln -nfs "$(which python3)" fake_bin/python
    ln -nfs "$(which pip3)" fake_bin/pip
    export PATH="$PWD/fake_bin:$PATH"
  fi
fi

BOOST_NO_PYTHON=
if [[ ! $BOOST_PYTHON ]]; then
  BOOST_NO_PYTHON=1
fi

if [[ $CXXSTD && $CXXSTD -ge 17 ]]; then
  # Use C++17: https://github.com/boostorg/system/issues/26#issuecomment-413631998
  CXXSTD=17
fi

TMPB2=$BUILDDIR/tmp-boost-build
case $ARCHITECTURE in
  osx*) TOOLSET=clang ;;
  *) TOOLSET=gcc ;;
esac

rsync -a "$SOURCEDIR"/ "$BUILDDIR"/
cd "$BUILDDIR"/tools/build
# This is to work around an issue in boost < 1.70 where the include path misses
# the ABI suffix. E.g. ../include/python3 rather than ../include/python3m.
# This is causing havok on different combinations of Ubuntu / Anaconda
# installations.
bash bootstrap.sh $TOOLSET
case $ARCHITECTURE in
  osx*)  ;;
  *) export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:$(python3 -c 'import sysconfig; print(sysconfig.get_path("include"))')" ;;
esac
mkdir -p $TMPB2
./b2 install --prefix=$TMPB2
export PATH=$TMPB2/bin:$PATH
cd $BUILDDIR
b2 -q                                                 \
   -d2                                                \
   ${JOBS+-j $JOBS}                                   \
   --prefix="$INSTALLROOT"                            \
   --build-dir=build-boost                            \
   --disable-icu                                      \
   --without-context                                  \
   --without-coroutine                                \
   --without-graph                                    \
   --without-graph_parallel                           \
   --without-locale                                   \
   --without-mpi                                      \
   ${BOOST_NO_PYTHON:+--without-python}               \
   --debug-configuration                              \
   -sNO_ZSTD=1                                        \
   ${BZ2_ROOT:+-sBZIP2_INCLUDE="$BZ2_ROOT/include"}   \
   ${BZ2_ROOT:+-sBZIP2_LIBPATH="$BZ2_ROOT/lib"}       \
   ${ZLIB_ROOT:+-sZLIB_INCLUDE="$ZLIB_ROOT/include"}  \
   ${ZLIB_ROOT:+-sZLIB_LIBPATH="$ZLIB_ROOT/lib"}      \
   ${LZMA_ROOT:+-sLZMA_INCLUDE="$LZMA_ROOT/include"}  \
   ${LZMA_ROOT:+-sLZMA_LIBPATH="$LZMA_ROOT/lib"}      \
   toolset=$TOOLSET                                   \
   link=shared                                        \
   threading=multi                                    \
   variant=release                                    \
   ${BOOST_CXXFLAGS:+cxxflags="$BOOST_CXXFLAGS"}      \
   ${CXXSTD:+cxxstd=$CXXSTD}                          \
   install

# If boost_python is enabled, check if it was really compiled
[[ $BOOST_PYTHON ]] && ls -1 "$INSTALLROOT"/lib/*boost_python* > /dev/null

# We need to tell boost libraries linking other boost libraries to look for them
# inside the same directory as the main ones, on macOS (@loader_path).
if [[ $ARCHITECTURE == osx* ]]; then
  for LIB in "$INSTALLROOT"/lib/libboost*.dylib; do
    otool -L "$LIB" | grep -v "$(basename "$LIB")" | { grep -oE 'libboost_[^ ]+' || true; } | \
      xargs -I{} install_name_tool -change {} @loader_path/{} "$LIB"
  done
fi

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --cmake > etc/modulefiles/"$PKGNAME"
cat << EOF >> etc/modulefiles/"$PKGNAME"
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
mkdir -p "$INSTALLROOT"/etc/modulefiles && rsync -a --delete etc/modulefiles/ "$INSTALLROOT"/etc/modulefiles
