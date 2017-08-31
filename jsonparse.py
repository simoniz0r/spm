# Title: spm
# Description: Downloads AppImages and moves them to /usr/local/bin/.  Can also upgrade and remove installed AppImages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

import sys
import json
data = json.load(sys.stdin)
print data[sys.argv[1]][sys.argv[2]]
