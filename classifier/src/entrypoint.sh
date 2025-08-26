#!/bin/sh -e

# Read in the file of environment settings
. ../.env

# Then run the CMD
set -x
exec "$@"