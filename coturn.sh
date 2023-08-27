#!/bin/bash

# No promtheus support in apt version 4.5.1 - for this you need >= 4.5.2
sudo apt-get install -y coturn 

# For 4.5.2 with prometheus support you need to compile from scratch:

exit 1