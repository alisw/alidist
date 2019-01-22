package: yacc-like
version: "1.0"
tag: ad9a652456adfe2a554fd2542dd4831575b2be03
source: https://github.com/alisw/yacc-like
prefer_system: .*
prefer_system_check: |
  set -e
  export PATH=$(brew --prefix bison)/bin:$PATH
  which bison
  # We need 2.5 or better
  case `bison --version | head -n 1| sed -e's/.* //'` in
    1.*|2.1*|2.2*|2.3*|2.4*) false ;;
    *) ;;
  esac
  which flex
build_requires:
 - autotools
---
rsync -a --delete --exclude="**/.git" $SOURCEDIR/ ./
pushd bison
  autoreconf -ivf
  ./configure --prefix ${INSTALLROOT} --disable-manpages

  make ${JOBS:+-j $JOBS}
  make install
popd
pushd flex
  autoreconf -ivf
  ./configure --prefix ${INSTALLROOT} --disable-manpages

  make ${JOBS:+-j $JOBS}
  make install
popd
