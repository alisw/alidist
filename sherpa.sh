package: SHERPA
version: "%(tag_basename)s"
tag: "v2.2.8-alice1"
source: https://github.com/alisw/SHERPA
requires:
  - "GCC-Toolchain:(?!osx)"
  - Openloops
  - HepMC
  - lhapdf-pdfsets
  - fastjet
build_requires:
  - system-curl
  - autotools
  - cgal
  - GMP
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

# SHERPA's configure uses wget which might not be there
mkdir -p fakewget && [[ -d fakewget ]]
printf '#!/bin/bash\nexec curl -fO $1' > fakewget/wget && chmod +x fakewget/wget

PATH=$PATH:fakewget 
export LDFLAGS="$LDFLAGS -L$CGAL_ROOT/lib  -L$GMP_ROOT/lib"
./configure --prefix=$INSTALLROOT        \
              --with-sqlite3=install       \
              --enable-hepmc2=$HEPMC_ROOT  \
              --enable-lhapdf=$LHAPDF_ROOT \
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
