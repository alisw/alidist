package: yacc-like
version: "1.0"
system_requirement_missing: |
   Please install bison and flex develpment package on your system.
   If they are there, make sure you have them in your default path.
system_requirement: ".*"
system_requirement_check: |
   command -v bison && command -v flex
---
