package: Common-O2
version: "%(tag_basename)s"
tag: v1.6.3
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/AliceO2Group/Common
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) 
      [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
    ;;
esac

cmake $SOURCEDIR 				\
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT 	\
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT} 	\
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --cmake > etc/modulefiles/$PKGNAME
cat << EOF >> etc/modulefiles/$PKGNAME
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
