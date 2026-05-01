#!/bin/bash
set -euo pipefail
SCRIPT_DIR=`dirname "$(realpath $0)"`
# Prepares a directory with the container image.
# The directory later serves as the container home directory.
mkdir -p ~/apphome
cd ~/apphome
echo $SCRIPT_DIR

# if apptainer is not available by default, load the module
# module load apptainer

apptainer build --fakeroot cuda.sif $SCRIPT_DIR/mycontainer.def
