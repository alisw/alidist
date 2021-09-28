package: osx-system-openssl
version: "1.0"
system_requirement_missing: |
  Please make sure you install openssl using Homebrew (brew install openssl@1.1)
system_requirement: "osx.*"
system_requirement_check: |
  echo '#include <openssl/bio.h>' | c++ -x c++ - -I`brew --prefix openssl@1.1`/include -c -o /dev/null
---

