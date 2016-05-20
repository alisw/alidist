package: opengl
version: "1.0"
system_requirement_missing: "Please install OpenGL (and X11) development packages on your system"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <GL/glu.h>\n" | c++ -xc++ - -c -o /dev/null
---

