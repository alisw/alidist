package: autotools
version: "%(tag_basename)s"
tag: v1.6.4
license: GPL-3.0
source: https://github.com/alisw/autotools
prefer_system: "(?!slc5|slc6)"
prefer_system_check: |
  export PATH=$PATH:$(brew --prefix gettext || true)/bin:$(brew --prefix texinfo || true)/bin;
  which autoconf && which m4 && which automake && which makeinfo && which aclocal && which pkg-config && which autopoint && which libtool;
  if [ $? -ne 0 ]; then printf "One or more autotools packages are missing on your system.\n * On a RHEL-compatible system you probably need: autoconf automake texinfo gettext gettext-devel libtool\n * On an Ubuntu-like system you probably need: autoconf automake autopoint texinfo gettext libtool libtool-bin pkg-config\n * On macOS you need: brew install autoconf automake gettext pkg-config"; exit 1; fi
prepend_path:
  PKG_CONFIG_PATH: $(pkg-config --debug 2>&1 | grep 'Scanning directory' | sed -e "s/.*'\(.*\)'/\1/" | xargs echo | sed -e 's/ /:/g')
build_requires:
  - termcap
  - make
---
#!/bin/bash -e

unset CXXFLAGS
# Not unset: GCC 14 turns implicit declarations, implicit int and mismatched
# pointers into errors, and these sources predate that. gettext 0.20.1 calls
# free() without <stdlib.h>, for one.
export CFLAGS="-Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion -Wno-incompatible-pointer-types"
export EMACS=no

case $ARCHITECTURE in
  slc6*) USE_AUTORECONF=${USE_AUTORECONF:="false"} ;;
  *) USE_AUTORECONF=${USE_AUTORECONF:="true"} ;;
esac

echo "Building ALICE autotools. To avoid this install autoconf, automake, autopoint, texinfo, pkg-config."

# Restore original timestamps to avoid reconf (Git does not preserve them)
pushd $SOURCEDIR
  ./missing-timestamps.sh --apply
popd

rsync -a --delete --exclude '**/.git' $SOURCEDIR/ .

# Use our auto* tools as we build them
export PATH=$INSTALLROOT/bin:$PATH
export LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH

# help2man
if pushd help2man*; then
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
  popd
fi

# m4 -- requires: nothing special
pushd m4*
  # texinfo uses utf-8 by default, but doc/m4.text is still iso-8859-1.
  # MacOS sed only understands the command with the linebreaks like this.
  sed -i.bak '1i\
@documentencoding ISO-8859-1
' doc/m4.texi
  rm -f doc/m4.texi.bak
  $USE_AUTORECONF && autoreconf -ivf
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# autoconf -- requires: m4
# FIXME: is that really true? on slc7 it fails if I do it the other way around
# with the latest version of autoconf / m4
pushd autoconf*
  $USE_AUTORECONF && autoreconf -ivf
  ./configure --prefix $INSTALLROOT
  make MAKEINFO=true ${JOBS+-j $JOBS}
  make MAKEINFO=true install
  hash -r
popd

# libtool -- requires: m4
pushd libtool*
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT --enable-ltdl-install
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# automake -- requires: m4, autoconf. Must come before gettext, whose
# autoreconf needs our aclocal rather than the host's.
pushd automake*
  if $USE_AUTORECONF && [ -e bootstrap ]; then sh ./bootstrap; fi
  ./configure --prefix $INSTALLROOT
  make MAKEINFO=true ${JOBS+-j $JOBS}
  make MAKEINFO=true install
  hash -r
popd


# gettext -- requires: nothing special
pushd gettext*
  $USE_AUTORECONF && autoreconf -ivf

  # Do not let make re-run bison on the shipped parsers.
  #
  # gettext-runtime/intl/Makefile.am hardcodes
  #
  #   YACC = @INTLBISON@ -y -d
  #   $(YACC) $(BISONFLAGS) --output plural.c ... && rm -f plural.c plural.h
  #
  # so the rule generates plural.h (that is what -d does) and then deletes it,
  # keeping a plural.c that opens with #include "plural.h". Any firing of that
  # rule therefore produces a source that cannot compile:
  #
  #   plural.c:133:10: fatal error: plural.h: No such file or directory
  #
  # This is not a bison-version problem -- 3.0.4, 3.7.4 and 3.8.2 all behave
  # identically, and all pass the version gate in m4/intl.m4, so upstream's own
  # guard (INTLBISON=: when bison is missing or too old) never engages for us.
  # intl.m4 admits the hazard in as many words: "some people carelessly touch
  # the files ... hence the plural.c rule will sometimes fire".
  #
  # The only reliable prevention is to keep the shipped .c newer than the .y, so
  # make never considers it out of date. missing-timestamps.sh above aims at the
  # same thing (git does not preserve mtimes); this makes it explicit for the
  # three generated parsers rather than relying on it.
  for parser in gettext-runtime/intl/plural gettext-tools/src/cldr-plural \
                gettext-tools/src/po-gram-gen; do
    # if/then rather than `[ -f ] && touch`: the latter leaves $? at 1 when the
    # last file is absent, which is harmless before ./configure but a trap for
    # whoever moves this next.
    if [ -f "$parser.c" ]; then touch "$parser.c"; fi
  done

  ./configure --prefix $INSTALLROOT \
              --without-xz \
              --without-bzip2 \
              --disable-curses \
              --disable-openmp \
              --enable-relocatable \
              --disable-rpath \
              --disable-nls \
              --disable-native-java \
              --disable-acl \
              --disable-java \
              --disable-dependency-tracking \
	      --without-emacs \
              --disable-silent-rules
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# pkgconfig -- requires: nothing special
pushd pkg-config*
  OLD_LDFLAGS="$LDFLAGS"
  [[ ${ARCHITECTURE:0:3} == osx ]] && export LDFLAGS="$LDFLAGS -framework CoreFoundation -framework Carbon"
  ./configure --disable-debug \
              --prefix=$INSTALLROOT \
              --disable-host-tool \
              --with-internal-glib
  export LDFLAGS="$OLD_LDFLAGS"
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# We need to detect OSX becase xargs behaves differently there
XARGS_DO_NOT_FAIL='-r'
[[ ${ARCHITECTURE:0:3} == osx ]] && XARGS_DO_NOT_FAIL=

# Fix perl location, required on /usr/bin/perl
grep -l -R -e '^#!.*perl' $INSTALLROOT | \
  xargs ${XARGS_DO_NOT_FAIL} -n1 sed -ideleteme -e 's;^#!.*perl;#!/usr/bin/perl;'
find $INSTALLROOT -name '*deleteme' -delete
grep -l -R -e 'exec [^ ]*/perl' $INSTALLROOT | \
  xargs ${XARGS_DO_NOT_FAIL} -n1 sed -ideleteme -e 's;exec [^ ]*/perl;exec /usr/bin/perl;g'
find $INSTALLROOT -name '*deleteme' -delete

# Pretend we have a modulefile to make the linter happy (don't delete)
#%Module
