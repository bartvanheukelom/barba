# source this file at the beginning of a script to do the following default setup, e.g.:
#
#     #!/bin/bash
#     source "$(dirname "$0")/barba/script_entry.sh"

source "$(dirname "$BASH_SOURCE")/barba.sh"
import utils
script_entry
