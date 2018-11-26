package: defaults-o2-dev-fairroot
version: v1
env:
  CXXFLAGS: "-fPIC -O2 -std=c++17"
  CFLAGS: "-fPIC -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  CXXSTD: "17"
  CMAKE_GENERATOR: "Ninja"
  GEANT4_BUILD_MULTITHREADED: "ON"
disable:
  - AliEn-Runtime
  - AliRoot
overrides:
  autotools:
    tag: v1.5.0
  boost:
    tag: "v1.68.0"
    requires:
      - "GCC-Toolchain:(?!osx)"
      - Python-modules
      - libpng
      - lzma
    prefer_system_check: |
      printf "#include \"boost/version.hpp\"\n# if (BOOST_VERSION < 106800 || BOOST_VERSION > 106899)\n#error \"Cannot use system's boost: boost 1.68 required.\"\n#endif\nint main(){}" | gcc -I$(brew --prefix boost)/include -xc++ - -o /dev/null
  GCC-Toolchain:
    tag: v7.3.0-alice1
    prefer_system_check: |
      set -e
      which gfortran || { echo "gfortran missing"; exit 1; }
      which cc && test -f $(dirname $(which cc))/c++ && printf "#define GCCVER ((__GNUC__ << 16)+(__GNUC_MINOR__ << 8)+(__GNUC_PATCHLEVEL__))\n#if (GCCVER < 0x070300)\n#error \"System's GCC cannot be used: we need at least GCC 7.X. We are going to compile our own version.\"\n#endif\n" | cc -xc++ - -c -o /dev/null
  ROOT:
    tag: "v6-14-04"
    source: https://github.com/root-mirror/root
    requires:
      - arrow
      - GSL
      - opengl:(?!osx)
      - Xdevel:(?!osx)
      - FreeType:(?!osx)
      - Python-modules
      - libxml2
      - OpenSSL:(?!osx)
      - "GCC-Toolchain:(?!osx)"
      - libpng
      - lzma
    build_requires:
      - CMake
      - "Xcode:(osx.*)"
      - ninja
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included)\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null
  protobuf:
    version: "%(tag_basename)s"
    tag: "v3.5.2"
  Ppconsul:
    build_requires:
      - CMake
      - ninja
  O2:
    version: "%(short_hash)s%(defaults_upper)s"
    tag: dev
    build_requires:
      - lcov
      - ninja
      - RapidJSON
      - googlebenchmark
      - AliTPCCommon
      - cub
  CMake:
    version: "%(tag_basename)s"
    tag: "v3.11.0"
    prefer_system_check: |
      which cmake && case `cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3 | head -n1` in [0-2]*|3.[0-9].*|3.10.*) exit 1 ;; esac
  FairRoot:
    version: dev
    tag: dev
    source: https://github.com/FairRootGroup/FairRoot
    build_requires:
      - googletest
      - ninja
  FairMQ:
    version: dev
    tag: dev
    source: https://github.com/FairRootGroup/FairMQ
  GEANT4:
    tag: v10.3.3
    source: https://gitlab.cern.ch/geant4/geant4.git
  GEANT4_VMC:
    tag: "v3-5-p2"
    source: https://github.com/vmc-project/geant4_vmc
  vgm:
    tag: "v4-4"
    source: https://github.com/vmc-project/vgm
  msgpack:
    version: "v3.1.1"
    tag: cpp-3.1.1
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
