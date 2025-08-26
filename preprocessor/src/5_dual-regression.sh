#!/bin/sh
# This script runs Dual Regression
# Using Dual Regression to investigate group differences
# A dual regression analysis is used to map the RSNs (i.e. group-level components or an external template or set of ROIs)
# back into individual subjects data, e.g. in order to examine between-group difference in the RSNs. We will use the group
# ICA generated from melodic in the section Running Group ICA as spatial basis to input into dual regression. 
# https://open.win.ox.ac.uk/pages/fslcourse/practicals/ica/index.html
#
# USAGE:
# ./5_dual-regression.sh subjects.txt \
#     "/mnt/f/data/output/fsl/general/dual-regression" \
#     "/mnt/f/data/output/fsl/general/melodic/dim-25_app-concat" \
#     experiment-name \
#     5000 \
#     1
#
# Inputs: 
# - OUTPUT_DIR - Base output dir for dual regression
# - MELODIC_IC_FILE - output directory with results from group ICA
#
# about 11h (72 subjects) or 7 minutes (without stage 3)
# 4gb (72 subjects)
# refs https://www.cnblogs.com/minks/p/5127366.html
# INPUT PARAMS #######################################################################
. ./utils.sh

DUAL_REGRESSION_OUTPUT_DIR=${1}
MELODIC_IC_FILE=${2}
GROUP_ICA_INPUT_FILE=${3}

#0 or 1 (1 is recommended). Whether to variance-normalise the timecourses used as the stage-2 regressors
VARIANCE_NORMALIZE=${4:-1}


#if GROUP_ICA_INPUT_FILE or MELODIC_IC_FILE are not set, show a error message and exit
if [ -z "$GROUP_ICA_INPUT_FILE" ] || [ -z "$MELODIC_IC_FILE" ]; then
    log "Error: MELODIC_IC_FILE and GROUP_ICA_INPUT_FILE (group_ica_input.txt) are required"
    exit 1
fi

#if DUAL_REGRESSION_OUTPUT_DIR exists, print a message and exit
if [ -d "$DUAL_REGRESSION_OUTPUT_DIR" ]; then
    log "Error: DUAL_REGRESSION_OUTPUT_DIR already exists: ${DUAL_REGRESSION_OUTPUT_DIR}"
    exit 1
fi

# OTHER VARIABLES #######################################################################

CONFIG_OUTPUT_FILE="${DUAL_REGRESSION_OUTPUT_DIR}/config.txt"

mkdir -p $DUAL_REGRESSION_OUTPUT_DIR

# print config to CONFIG_OUTPUT_FILE so it can be tracked later
log "DUAL_REGRESSION_OUTPUT_DIR: ${DUAL_REGRESSION_OUTPUT_DIR}"
log "GROUP_ICA_INPUT_FILE: ${GROUP_ICA_INPUT_FILE}"
log "VARIANCE_NORMALIZE: ${VARIANCE_NORMALIZE}"
log "DUAL_REGRESSION_OUTPUT_DIR: ${DUAL_REGRESSION_OUTPUT_DIR}"
# done printing config

log "Starting Dual Regression"
log "Input file is ${GROUP_ICA_INPUT_FILE}"

# Dual regression called without design and contrast matrices (no stage 3)
dual_regression \
  "${MELODIC_IC_FILE}" \
  ${VARIANCE_NORMALIZE} \
  -1 \
  0 \
  "${DUAL_REGRESSION_OUTPUT_DIR}/fsl-dual-regression" \
  `cat "${GROUP_ICA_INPUT_FILE}"` | tee -a "$LOGFILE"

log "Done"

log "Finished Dual Regression"
log "DUAL_REGRESSION_OUTPUT_DIR: ${DUAL_REGRESSION_OUTPUT_DIR}"

#fsleyes -std groupICA15/melodic_IC.nii.gz \
#  -un -cm red-yellow -nc blue-lightblue -dr 4 15 \
#   dual_regression_out/dr_stage3_ic0007_tfce_corrp_tstat1.nii.gz \
#  -cm green -dr 0.95 1

# https://waikato.github.io/weka-wiki/downloading_weka/

## HELPER: 
##  RENDERING IMAGES http://andrewreineberg.com/guides/01-ica.html

# printing results:
# http://andrewreineberg.com/guides/02-dual_reg.html