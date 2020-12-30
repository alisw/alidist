package: SHERPA
version: "%(tag_basename)s"
tag: "v2.2.10"
source: https://gitlab.com/sherpa-team/sherpa.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - Openloops
  - HepMC
  - lhapdf-pdfsets
  - fastjet
  - pythia
build_requires:
  - system-curl
  - "autotools:(slc6|slc7)"
  - cgal
  - GMP
  - alibuild-recipe-tools
---
#!/bin/bash -e

# When using the official repo the .git files are needed as Git_Info.C
# is generated and used during the build process, which fails in case 
# we would not include the .git directory
rsync -a $SOURCEDIR/ ./

# Exclude building Manual from Makefile.am
mv Makefile.am Makefile.am.in
cat Makefile.am.in | grep -v Manual >> Makefile.am
rm Makefile.am.in


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
