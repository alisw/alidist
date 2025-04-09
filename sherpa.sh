package: SHERPA
version: "%(tag_basename)s"
tag: "v2.2.16"
source: https://gitlab.com/sherpa-team/sherpa.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - Openloops
  - HepMC
  - HepMC3
  - lhapdf
  - lhapdf-pdfsets
  - fastjet
  - pythia
  - sqlite
build_requires:
  - "autotools:(slc6|slc7)"
  - cgal
  - GMP
  - alibuild-recipe-tools
  - curl
---
#!/bin/bash -e

# When using the official repo the .git files are needed as Git_Info.C
# is generated and used during the build process, which fails in case 
# we would not include the .git directory
rsync -a --chmod=ug=rwX --exclude .git  --delete-excluded $SOURCEDIR/ ./

# Exclude building Manual from Makefile.am
sed -i.bak /Manual/d Makefile.am
rm -f Makefile.am.bak

[[ "X$SQLITE_ROOT" = X ]] && SQLITE_ROOT=$(brew --prefix sqlite)

autoreconf -ivf

# SHERPA's configure uses wget which might not be there
mkdir -p fakewget
printf '#!/bin/sh\nexec curl -fO "$1"\n' > fakewget/wget
chmod +x fakewget/wget
# Prepend fakewget to PATH so we always use it, to avoid OpenSSL conflicts.
export PATH="$PWD/fakewget:$PATH"

export LDFLAGS="$LDFLAGS -L$CGAL_ROOT/lib  -L$GMP_ROOT/lib"
./configure --prefix=$INSTALLROOT        \
              --with-sqlite3=$SQLITE_ROOT \
              --enable-hepmc2=$HEPMC_ROOT  \
              --enable-hepmc3=$HEPMC3_ROOT \
              --enable-lhapdf=$LHAPDF_ROOT \
              --enable-pythia \
              --enable-openloops=$OPENLOOPS_ROOT \
        	  --enable-fastjet=$FASTJET_ROOT

make ${JOBS+-j $JOBS}
make install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set SHERPA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv SHERPA_ROOT \$SHERPA_ROOT
setenv SHERPA_INSTALL_PATH \$::env(SHERPA_ROOT)/lib/SHERPA
setenv SHERPA_SHARE_PATH \$::env(SHERPA_ROOT)/share/SHERPA-MC
prepend-path PATH \$SHERPA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$SHERPA_ROOT/lib
prepend-path LD_LIBRARY_PATH \$SHERPA_ROOT/lib/SHERPA-MC
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
