package: Python-modules-ml
version: "1.0"
requires:
  - Python3
  - Python-modules
#build_requires:
#  - curl
prefer_system: (?!slc5)
prefer_system_check:
  python -c 'import pandas,scipy,seaborn,uproot,sklearn,sklearn_evaluation,xgboost,tensorflow,keras';
  if [ $? -ne 0 ]; then printf "Required Python modules are missing. You can install them with pip (better as root):\n  pip install pandas scipy seaborn uproot scikit-learn sklearn-evaluation xgboost tensorflow keras\n"; exit 1; fi
---
#!/bin/bash -ex

if [[ ! $PYTHON_VERSION ]]; then
  cat <<EoF
Building our own Python modules for ML.
If you want to avoid this please install the following modules (pip recommended):

  - pandas 
  - scipy 
  - seaborn
  - uproot 
  - scikit-learn 
  - sklearn-evaluation
  - xgboost 
  - tensorflow 
  - keras

EoF
fi

# Force pip installation of packages found in current PYTHONPATH
unset PYTHONPATH
unset PYTHONHOME

# The X.Y in pythonX.Y
export PYVER=$(python -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')

# Install as much as possible with pip. Packages are installed one by one as we
# are not sure that pip exits with nonzero in case one of the packages failed.
export PYTHONUSERBASE=$INSTALLROOT

VENV=$(python -c 'import sys; print ("1" if hasattr(sys, "real_prefix") else "0")')
# CAVEAT: this is not tested
PYVENV=$(python -c 'import sys; print ("1" if (hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix) else "0")')

# Newer tensorflow versions require AVX support
tf_ver=""
if [[ `lscpu` != *"avx"* ]]; then
   tf_ver="==1.5"
fi

#for X in "pandas"             
for X in "pandas"             \
         "scipy"              \
         "seaborn"            \
         "uproot"             \
         "scikit-learn==0.18"       \
         "sklearn-evaluation" \
         "tensorflow$tf_ver"  \
         "xgboost"            \
         "keras"
do
  if [[ ${VENV} -eq "1"  ||  ${PYVENV} -eq "1" ]]; then
      pip install $X
  else    
      pip install --user $X
  fi

done

#unset PYTHONUSERBASE
#mkdir -p $INSTALLROOT/{lib,lib64}/python$PYVER/site-packages

# Build tensorflow from source in order to be independent from glibc version
#yum -y install bazel
#TF_GITREF=""

# Fix shebangs to point to the correct Python from the runtime environment
grep -IlRE '#!.*python' $INSTALLROOT/bin | \
  xargs -n1 perl -p -i -e 's|^#!.*/python|#!/usr/bin/env python|'

# Test whether we can load Python modules (this is not obvious as some of them
# do not indicate some of their dependencies and break at runtime).
PYTHONPATH=$INSTALLROOT/lib64/python$PYVER/site-packages:$INSTALLROOT/lib/python$PYVER/site-packages:$PYTHONPATH \
  python -c "import pandas,scipy,seaborn,uproot,sklearn,sklearn_evaluation,xgboost,tensorflow,keras"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${PYTHON3_VERSION:+Python3/$PYTHON3_VERSION-$PYTHON3_REVISION} ${PYTHON_MODULES_VERSION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION} ${ALIEN_RUNTIME_VERSION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION} ${ROOT_VERSION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
setenv PYTHON_MODULES_ML_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(PYTHON_MODULES_ML_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(PYTHON_MODULES_ML_ROOT)/lib64
prepend-path LD_LIBRARY_PATH $::env(PYTHON_MODULES_ML_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_MODULES_ML_ROOT)/lib64" && \
                                      echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_MODULES_ML_ROOT)/lib")
prepend-path PYTHONPATH $::env(PYTHON_MODULES_ML_ROOT)/lib/python$PYVER/site-packages
EoF
