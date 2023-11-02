package: Python-modules-list
version: "1.0"
env:
  PIP_BASE_REQUIREMENTS: |
    pip==21.3.1
    setuptools==59.6.0
    wheel==0.37.1
  PIP_REQUIREMENTS: |
    requests==2.27.1
    ipykernel==5.1.0
    ipython==7.4.0
    ipywidgets==7.4.2
    metakernel==0.20.14
    mock==2.0.0
    notebook==5.7.8
    scons==4.1.0
  PIP36_REQUIREMENTS: |
    PyYAML==6.0.1
    psutil==5.8.0
    uproot==4.1.0
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
    PyYAML==6.0.1
    psutil==5.8.0
    uproot==4.1.0
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
    PyYAML==6.0.1
    psutil==5.8.0
    uproot==4.1.0
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
    PyYAML==6.0.1
    psutil==5.8.0
    uproot==4.1.0
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
  # Keep the PIPxy version in sync with the Conda env we install in Python-modules!
  # Everything but the first two lines copied from PIP39_REQUIREMENTS, but with versions
  # adjusted such that wheels are available and for compatibility with tensorflow.
  PIP39_REQUIREMENTS_osx_arm64: |
    tensorflow-macos==2.13.0
    tensorflow-metal==1.0.1
    PyYAML==6.0.1
    psutil==5.9.5
    uproot==4.1.0
    numpy==1.23.5
    scipy==1.10.1
    Cython==0.29.21
    seaborn==0.11.0
    scikit-learn==1.2.2
    sklearn-evaluation==0.12.0
    Keras==2.13.1
    xgboost==1.7.5
    dryable==1.0.5
    responses==0.10.6
    pandas==1.5.3
  PIP310_REQUIREMENTS: |
    PyYAML==6.0.1
    psutil==5.9.0
    uproot==4.1.0
    numpy==1.23.4
    scipy==1.9.3
    Cython==0.29.21
    seaborn==0.11.0
    scikit-learn==0.24.1
    sklearn-evaluation==0.8.1
    Keras==2.4.3
    xgboost==1.2.0
    dryable==1.0.5
    responses==0.10.6
    pandas==1.1.5
  PIP311_REQUIREMENTS: |
    PyYAML==6.0.1
    psutil==5.9.5
    uproot==4.1.0
    numpy==1.23.5
    scipy==1.10.1
    Cython==0.29.21
    seaborn==0.11.0
    scikit-learn==1.3.0
    sklearn-evaluation==0.12.0
    Keras==2.13.1
    xgboost==1.7.5
    dryable==1.0.5
    responses==0.10.6
    pandas==1.5.3
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
