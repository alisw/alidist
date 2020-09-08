package: systemd
version: "237"
system_requirement_missing: |
   Please install systemd develpment package on your system.
   If they are there, make sure you have them in your default path or check you have `which` installed.
system_requirement: "(?!osx)"
system_requirement_check: |
   printf "#include <systemd/sd-daemon.h>" | cc -xc - -c -o /dev/null
---
