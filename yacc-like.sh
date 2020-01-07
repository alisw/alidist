package: yacc-like
version: "1.0"
system_requirement_missing: |
   Please install bison and flex develpment package on your system.
   If they are there, make sure you have them in your default path or check you have `which` installed.
system_requirement: ".*"
system_requirement_check: |
   export PATH=$(brew --prefix bison)/bin:$PATH
   export PATH=$(brew --prefix flex)/bin:$PATH
   which bison && which flex
---
