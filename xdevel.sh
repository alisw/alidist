package: Xdevel
version: "1.0"
system_requirement_missing: |
  Please install X development packages on your system.
  They might be called libx11-dev, libxpm-dev, libxext-dev and libxft-dev.
  On some systems they are called libX11-devel, libXpm-devel, libXext-devel and libXft-devel.
system_requirement: ".*"
system_requirement_check: |
  printf "#include <X11/Xlib.h>\n#include <X11/xpm.h>\n#include <X11/Xft/Xft.h>\n#include <X11/extensions/Xext.h>\n" | cc -xc - -I/opt/X11/include `freetype-config --cflags` -c -o /dev/null
---

