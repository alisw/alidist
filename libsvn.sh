package: libsvn
version: "1.0"
system_requirement_missing: "Please install the development packages of libsvn and libapr."
system_requirement: ".*"
system_requirement_check: "printf '#include <subversion-1/svn_version.h>\nint main(){}\n' | cc -xc - -I`apr-config --include`"
---

