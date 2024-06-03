
#!/bin/bash

# ----------------------------------------------------------------------
# mikes handy Timeshift filesystem-snapshot utility
# ----------------------------------------------------------------------
# this needs to be a lot more general, but the basic idea is it makes
# rotating Timeshift backup-snapshots of /home whenever called
# ----------------------------------------------------------------------


clear

sudo timeshift --list



sudo timeshift --check


sudo timeshift --create


sudo timeshift --list
