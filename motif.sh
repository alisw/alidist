package: motif
version: "1.0"
system_requirement_missing: "Please install motif and motif-devel"
system_requirement: ".*"
system_requirement_check: |
  printf "#include <Mrm/MrmAppl.h>\nint main() {}\n" | cc -xc - -o /dev/null
---
