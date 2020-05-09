package: gfortran-system
version: "1.0"
system_requirement_missing: |
  On macOS we require gfortran to be installed from brew.
  Please do so with:

    brew install gcc

system_requirement: "osx.*"
system_requirement_check: "gfortran --version"
---
