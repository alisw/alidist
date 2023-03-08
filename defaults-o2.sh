package: defaults-o2
version: v1
env:
  CXXFLAGS: "-fPIC -O2 -std=c++14"
  CFLAGS: "-fPIC -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "14"
disable:
  - AliEn-Runtime
  - grpc
  - Ppconsul
  - ApMon-CPP
overrides:
  autotools:
    tag: v1.5.0
  boost:
    tag: "v1.64.0-alice1"
    requires:
      - "GCC-Toolchain:(?!osx)"
      - Python-modules
    prefer_system_check: |
      printf "#include \"boost/version.hpp\"\n# if (BOOST_VERSION < 106400 || BOOST_VERSION > 106499)\n#error \"Cannot use system's boost: boost 1.64 required.\"\n#endif\nint main(){}" | gcc -I$(brew --prefix boost)/include -xc++ - -o /dev/null
  GCC-Toolchain:
    tag: v6.2.0-alice1
    prefer_system_check: |
      set -e
      which gfortran || { echo "gfortran missing"; exit 1; }
      which cc && test -f $(dirname $(which cc))/c++ && printf "#define GCCVER ((__GNUC__ << 16)+(__GNUC_MINOR__ << 8)+(__GNUC_PATCHLEVEL__))\n#if (GCCVER < 0x060200)\n#error \"System's GCC cannot be used: we need at least GCC 6.X. We are going to compile our own version.\"\n#endif\n" | cc -xc++ - -c -o /dev/null
  ROOT:
    version: "%(tag_basename)s"
    tag: "v6-12-04"
    source: https://github.com/root-mirror/root
    requires:
      - AliEn-Runtime:(?!.*ppc64)
      - GSL
      - opengl:(?!osx)
      - Xdevel:(?!osx)
      - FreeType:(?!osx)
      - Python-modules
      - "GCC-Toolchain:(?!osx)"
      - libpng
      - lzma
  AliRoot:
    version: "%(commit_hash)s_O2"
    tag: "v5-09-20v"
    requires:
      - ROOT
      - fastjet:(?!.*ppc64)
      - GEANT3
      - GEANT4_VMC
      - Vc
      - ZeroMQ
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included)\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null
  protobuf:
    version: "%(tag_basename)s"
    tag: "v3.0.2"
  CMake:
    version: "%(tag_basename)s"
    tag: "v3.9.4"
    prefer_system_check: |
      which cmake && case `cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3 | head -n1` in [0-2]*|3.[0-8].*|3.9.[0-3]) exit 1 ;; esac
  pythia:
    requires:
      - lhapdf
      - boost
  AliPhysics:
    version: "%(commit_hash)s_O2"
    tag: "v5-09-20v-01"
  GEANT4:
    tag: v10.3.3
    source: https://gitlab.cern.ch/geant4/geant4.git
  GEANT4_VMC:
    tag: "v3-5"
    source: https://github.com/vmc-project/geant4_vmc
  vgm:
    tag: "v4-4"
    source: https://github.com/vmc-project/vgm
  GEANT3:
    tag: v2-5
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
