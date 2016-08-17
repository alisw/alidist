package: opengl
version: "1.0"
system_requirement_missing: "Please install the OpenGL development packages on your system"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <GL/glu.h>\n" | cc -xc - -c -o /dev/null
---

