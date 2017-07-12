package: opengl
version: "1.0"
system_requirement_missing: |
  OpenGL development packages are missing on your system.
    * On RHEL-compatible systems you probably need: mesa-libGLU-devel
    * On Ubuntu-compatible systems you probably need: libglu1-mesa-dev
system_requirement: ".*"
system_requirement_check: |
  printf "#include <GL/glu.h>\n" | cc -xc - -c -o /dev/null
---

