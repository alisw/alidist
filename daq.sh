package: DAQ
version: v1
---
#!/bin/bash -e
# We do nothing but checking that those packages are installed.
rpm -q date amore daqDA-lib ACT
