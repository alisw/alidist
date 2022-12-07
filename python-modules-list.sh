package: Python-modules-list
version: "1.0"
env:
  PIP_REQUIREMENTS: |
    requests==2.27.1
    ipykernel==5.1.0
    ipython==7.4.0
    ipywidgets==7.4.2
    metakernel==0.20.14
    mock==2.0.0
    notebook==5.7.8
    PyYAML==5.1
    uproot==4.1.0
    psutil==5.8.0
    scons==4.1.0
  PIP36_REQUIREMENTS: |
    numpy==1.16.2
    scipy==1.2.1
    Cython==0.29.16
    seaborn==0.9.0
    sklearn-evaluation==0.4
    Keras==2.2.4
    tensorflow==1.13.1
    xgboost==0.82
    dryable==1.0.3
    responses==0.10.6
    pandas==0.24.2
    scikit-learn==0.20.3
  PIP38_REQUIREMENTS: |
    scipy==1.6.1
    Cython==0.29.21
    seaborn==0.9.0
    sklearn-evaluation==0.4
    Keras==2.4.3
    tensorflow==2.4.1
    xgboost==1.3.3
    numpy==1.19.5
    dryable==1.0.3
    responses==0.10.6
    pandas==1.2.3
    scikit-learn==0.24.1
  PIP39_REQUIREMENTS: |
    numpy==1.21.4
    scipy==1.7.3
    Cython==0.29.21
    seaborn==0.11.0
    scikit-learn==0.24.1
    sklearn-evaluation==0.5.2
    Keras==2.4.3
    xgboost==1.2.0
    dryable==1.0.5
    responses==0.10.6
    pandas==1.1.5
  "PIP39_REQUIREMENTS_ubuntu2110_x86_64": |
    setuptools<=60.8.2
    numpy==1.21.4
    scipy==1.7.3
    Cython==0.29.21
    seaborn==0.11.0
    scikit-learn==0.24.1
    sklearn-evaluation==0.5.2
    Keras==2.4.3
    xgboost==1.2.0
    dryable==1.0.5
    responses==0.10.6
    pandas==1.1.5
---
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
module load BASE/1.0
# Our environment
EoF
