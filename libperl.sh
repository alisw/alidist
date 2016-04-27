package: libperl
version: 1.0
system_requirement_missing: "Please install libperl development package on your system"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <EXTERN.h>\n#include <perl.h>\n" | gcc -xc++ -I`perl -MConfig -e 'print $Config{archlib}'`/CORE - -c -o /dev/null
---

