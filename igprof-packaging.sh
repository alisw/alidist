package: IgProf-packaging
version: master
source: https://github.com/alisw/ali-bot
force_rebuild: true
requires:
  - IgProf
---
#!/bin/bash -e
mkdir -p igprof/usr libunwind/usr libatomic_ops/usr
tar xzf /sw/TARS/$ARCHITECTURE/IgProf/IgProf-$IGPROF_VERSION-$IGPROF_REVISION.$ARCHITECTURE.tar.gz --strip-components=4 -C igprof/usr
tar xzf /sw/TARS/$ARCHITECTURE/libunwind/libunwind-$LIBUNWIND_VERSION-$LIBUNWIND_REVISION.$ARCHITECTURE.tar.gz --strip-components=4 -C libunwind/usr
tar xzf /sw/TARS/$ARCHITECTURE/libatomic_ops/libatomic_ops-$LIBATOMIC_OPS_VERSION-$LIBATOMIC_OPS_REVISION.$ARCHITECTURE.tar.gz --strip-components=4 -C libatomic_ops/usr

RPM_LIBATOMIC_OPS_VERSION=`echo $LIBATOMIC_OPS_VERSION | tr - _`

case $ARCHITECTURE in
  ubuntu*) 
    RPM_LIBATOMIC_OPS_VERSION=$LIBATOMIC_OPS_VERSION
    RPM_LIBATOMIC_OPS_NAME=libatomic-ops
    PACKAGE_FORMAT=deb 
    ARCH_SEP=_
    VERSION_SEP=_
    RPM_ARCH=amd64
    apt-get install -y python-requests ruby-dev
    gem install --no-ri --no-rdoc fpm
  ;;
  *) 
    RPM_LIBATOMIC_OPS_VERSION=`echo $LIBATOMIC_OPS_VERSION | tr - _`
    RPM_LIBUNWIND_VERSION=`echo $LIBUNWIND_VERSION | tr - _`
    RPM_LIBATOMIC_OPS_NAME=libatomic_ops
    PACKAGE_FORMAT=rpm 
    ARCH_SEP=.
    VERSION_SEP=-
    RPM_ARCH=x86_64
    yum install -y python-requests
  ;;
esac

cat << EOF > post-install
#!/bin/sh
ldconfig
EOF

fpm -s dir -t $PACKAGE_FORMAT \
    --after-install post-install \
    -d "libunwind = `echo $RPM_LIBUNWIND_VERSION | tr - _`" \
    --iteration $IGPROF_REVISION \
    -a $RPM_ARCH \
    -v $IGPROF_VERSION \
    -n igprof \
    -C igprof \
    usr/bin usr/lib usr/include

fpm -s dir -t $PACKAGE_FORMAT --iteration $LIBUNWIND_REVISION -a $RPM_ARCH -v $RPM_LIBUNWIND_VERSION -n libunwind -C libunwind usr/lib usr/include
fpm -s dir -t $PACKAGE_FORMAT --iteration $LIBATOMIC_OPS_REVISION -a $RPM_ARCH -v $LIBATOMIC_OPS_VERSION -n libatomic_ops -C libatomic_ops usr/lib usr/include

cat << EOF > packaging.yaml
architecture: $ARCHITECTURE
organization: igprof
description: IgProf test repository
format: $PACKAGE_FORMAT
labels:
  - profiling
  - development
packages:
  - name: igprof
    version: $IGPROF_VERSION
    file: igprof$VERSION_SEP$IGPROF_VERSION-$IGPROF_REVISION$ARCH_SEP$RPM_ARCH.$PACKAGE_FORMAT
    licenses: 
      - GPL-2.0
    vcs_url: "https://github.com/igprof/igprof.git"
    website_url: http://igprof.org
    labels: 
      - profiling
      - development
  - name: libunwind
    version: $LIBUNWIND_VERSION
    file: libunwind$VERSION_SEP$RPM_LIBUNWIND_VERSION-$LIBUNWIND_REVISION$ARCH_SEP$RPM_ARCH.$PACKAGE_FORMAT
    licenses: 
      - GPL-2.0
    vcs_url: "https://github.com/igprof/libunwind"
    labels: 
      - profiling
      - development
  - name: libatomic_ops
    version: $RPM_LIBATOMIC_OPS_VERSION
    file: $RPM_LIBATOMIC_OPS_NAME$VERSION_SEP$RPM_LIBATOMIC_OPS_VERSION-$LIBATOMIC_OPS_REVISION$ARCH_SEP$RPM_ARCH.$PACKAGE_FORMAT
    licenses: 
      - GPL-2.0
    vcs_url: "https://github.com/igprof/libatomic_ops"
    labels: 
      - profiling
      - development
level: test
EOF

ls
$SOURCEDIR/upload-bintray-distribution -u ktf packaging.yaml
