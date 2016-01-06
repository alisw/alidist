package: pythia6
version: "426"
---
#!/bin/sh
curl -O -fSsL --insecure http://cern.ch/service-spi/external/MCGenerators/distribution/pythia6/pythia6-426-src.tgz
tar xzvf pythia6-426-src.tgz
cd  pythia6/426

case $ARCHITECTURE in
  slc5*) 
    PLATF_CONF_OPTS="--enable-shared"
    PLATF_LDFLAGS=""
    PLATF_LD=""
    F77="`which gfortran`"
  ;;
  osx*) 
    PLATF_CONF_OPTS="--disable-shared --enable-static"
    PLATF_LDFLAGS=""
    PLATF_LD="LD='`which gcc`'" 
    F77="`which gfortran` -fPIC"
  ;;
  *) 
    PLATF_CONF_OPTS="--disable-shared --enable-static"
    PLATF_LDFLAGS=""
    PLATF_LD=""
    F77="`which gfortran` -fPIC"
  ;;
esac

autoreconf -ivf
# Unfortunately we need the two cases because LDFLAGS= does not work on linux
# and I couldn't get the space between use_dylibs and -Wl, preseved if
# I tried to have the whole "LDFLAGS=foo" in a variable.
case $ARCHITECTURE in
  osx*)
    ./configure $PLATF_CONF_OPTS --with-hepevt=4000 F77="$F77" \
    LD='`which gcc`' LDFLAGS='-Wl,-commons,use_dylibs -Wl,-flat_namespace' 
  ;;
  *)
    ./configure $PLATF_CONF_OPTS --with-hepevt=4000 F77="$F77" 
  ;;
esac

# NOTE: force usage of gcc to link shared libraries in place of gfortran since
# the latter causes a:
#
# ld: codegen problem, can't use rel32 to external symbol __gfortrani_compile_options in __gfortrani_init_compile_options
#
# error when building.
# I couldn't find any better way to replace "CC" in the F77 section of libtool.
case $ARCHITECTURE in
  slc5*) ;;
  *) perl -p -i -e 's|^CC=.*$|CC="gcc -fPIC"|' libtool ;;
esac

make
make install
tar -c lib include | tar -x -C $INSTALLROOT 

