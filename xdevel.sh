package: Xdevel
version: "1.0"
system_requirement_missing: |
  Please install X development packages on your system.
   * On RHEL-compatible systems you probably need: libX11-devel libXpm-devel libXext-devel libXft-devel
   * On Ubuntu-compatible systems you probably need: libxpm-dev libxext-dev libx11-dev libxft-dev
system_requirement: ".*"
system_requirement_check: |
  printf "#include <X11/Xlib.h>\n#include <X11/xpm.h>\n#include <X11/Xft/Xft.h>\n#include <X11/extensions/Xext.h>\n" | cc -xc - -I/opt/X11/include $(freetype-config --cflags 2> /dev/null ||  pkg-config freetype2 --cflags 2> /dev/null)  -c -o /dev/null
---

