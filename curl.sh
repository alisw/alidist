package: curl
version: "1.0"
system_requirement_missing: |
  curl and its development package are missing from your system.
   * RHEL-compatible systems: you will probably need "curl" and "curl-devel" packages.
   * Ubuntu-compatible systems: you will probably need "curl" and "libcurl4-openssl-dev" (or "libcurl4-gnutls-dev").
system_requirement: ".*"
system_requirement_check: |
  curl --version > /dev/null; if test $? = 127; then exit 1; else printf "#include <curl/curl.h>\nint main() {}\n" | cc -xc -lcurl - -o /dev/null || exit 2; fi; exit 0
---
