#!/bin/sh -e

# Read in the file of environment settings
. ../.env
. ${FSLDIR}/etc/fslconf/fsl.sh

# Then run the CMD
set -x
exec "$@"