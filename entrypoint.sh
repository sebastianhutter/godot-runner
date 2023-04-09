#!/bin/bash

CLI=$@
[ -z "${CLI}" ] && CLI="/bin/bash"
Xvfb -ac ${DISPLAY} -screen 0 1280x1024x24 > /dev/null 2>&1 &
exec gosu runner "${CLI}"