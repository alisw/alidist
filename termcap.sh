package: termcap
version: "1.0"
system_requirement_missing: "Please install the ncurses development package on your system (usually ncurses-devel or libncurses-dev)"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <termcap.h>\n" | cc -xc - -c -o /dev/null
---

