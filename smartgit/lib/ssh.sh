#!/bin/bash
"${GIT_SSH_orig}" -o BatchMode=yes "$@"
exit 0
