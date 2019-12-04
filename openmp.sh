package: openmp
version: 1.0
system_requirement_missing: |
  Please install openmp (libomp) on your system:
    * On MacOS systems: brew install libomp
    * On Linux it comes with the compiler
system_requirement: ".*"
system_requirement_check: |
  printf "#include <omp.h>\n" | c++ -xc++ - -c -o /dev/null
---

