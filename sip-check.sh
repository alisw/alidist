package: sip-check
version: 1.0
system_requirement_missing: |
  Please make sure you have SIP disabled. 

  See: 

      http://alisw.github.io/alibuild/troubleshooting.html#fastjet-fails-to-compile-on-my-brand-new-mac
  
  for more information.
system_requirement: "(osx.*)"
system_requirement_check: |
  csrutil status | grep disabled
---

