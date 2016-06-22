package: libperl
version: 1.0
system_requirement_missing: "Please install libperl and perl-ExtUtils-Embed development package on your system"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <EXTERN.h>\n#include <perl.h>\nint main() {return 0;}" | gcc -lperl -xc++ -I`perl -MConfig -e 'print $Config{archlib}'`/CORE - -o /dev/null && perl -MExtUtils::Embed -e 1
---
