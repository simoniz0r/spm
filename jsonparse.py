#!/usr/bin/env python3

import sys
import json
data = json.load(sys.stdin)
print (data[sys.argv[1]][sys.argv[2]])
