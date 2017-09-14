package: ms_gsl
version: "1"
source: https://github.com/Microsoft/GSL.git
tag: b014508
---
#!/bin/bash -e

# recipe for the C++ guidelines support library (Microsoft implementation)
# can be deleted once we are fully C++17 compliant

# just rsync into the installdir since header only
rsync -a $SOURCEDIR/include $INSTALLROOT
