#!/bin/sh
# This script runs BET
# ./1_bet.sh subjects.txt /mnt/e/data/output/fsl/general 0.3 0
# Inputs: 
# - SUBJECTS_FILE_NAME - txt file containing subjects to be processed (no header)
# - OUTPUT_BASE_DIR - output dir
# - BET_FRACTIONAL_INTENSITY_THRESHOLD
# - BET_VERTICAL_GRADIENT_IN_FRACTIONAL_INTENSITY_THRESHOLD

# OUTPUT: about 3MB anat file per subject (fast)
. ./utils.sh

# INPUT PARAMS #######################################################################
SUBJECTS_FILE=${1}
BRAIN_EXTRACTION_OUTPUT_DIR=${2}

# (default 0.5); smaller values give larger brain outline at the expense of including non-brain tissue
BET_FRACTIONAL_INTENSITY_THRESHOLD=${3}
# -g vertical gradient in fractional intensity threshold (-1, 1) , default 0; 
# positive values give larger brain outline at bottom, smaller at top
BET_VERTICAL_GRADIENT_IN_FRACTIONAL_INTENSITY_THRESHOLD_DEFAULT=0
BET_VERTICAL_GRADIENT_IN_FRACTIONAL_INTENSITY_THRESHOLD=${4:-$BET_VERTICAL_GRADIENT_IN_FRACTIONAL_INTENSITY_THRESHOLD_DEFAULT}

# TEMP VARS ##########################################################################
# output directory contains the params used to run the script, so it can be reused

mkdir -p $BRAIN_EXTRACTION_OUTPUT_DIR

log "Running BET"
log "Params:"
log "BET_FRACTIONAL_INTENSITY_THRESHOLD: ${BET_FRACTIONAL_INTENSITY_THRESHOLD}"
log "BET_VERTICAL_GRADIENT_IN_FRACTIONAL_INTENSITY_THRESHOLD: ${BET_VERTICAL_GRADIENT_IN_FRACTIONAL_INTENSITY_THRESHOLD}"

#SET THE NUMBER OF LINES OF SUBJECTS_FILE file to var TOTAL_COUNT
TOTAL_COUNT=$(grep -c . "$SUBJECTS_FILE")

log "Total subjects ${TOTAL_COUNT}. Output: ${BRAIN_EXTRACTION_OUTPUT_DIR}"

CURRENT_COUNT=0
#line format
#abide_version,site,sub_id,group,age,sex,full_iq,tr_seconds,slice_timing_file,total_volumes,functional_fmri_file,anatomical_fmri_file,total_voxels
while read line; do
    CURRENT_COUNT=$((CURRENT_COUNT+1))

    ABIDE_VERSION=$(echo $line | cut -d ',' -f 1)
    SITE=$(echo $line | cut -d ',' -f 2)
    SUB_ID=$(echo $line | cut -d ',' -f 3)
    ANATOMICAL_FMRI_FILE=$(echo $line | cut -d ',' -f 12)
    
    #remove the exension .nii.gz from ANATOMICAL_FMRI_FILE
    ANATOMICAL_FMRI_FILE_WO_EXTENSION=$(echo $ANATOMICAL_FMRI_FILE | cut -d '.' -f 1)

    log "[BET] Processing $CURRENT_COUNT of $TOTAL_COUNT: $ABIDE_VERSION - $SITE - $SUB_ID"

    ANAT_FILE_INPUT="${BIDS_INPUT_BASE_DIR}/${ANATOMICAL_FMRI_FILE_WO_EXTENSION}"
    BET_OUTPUT_DIRECTORY="${BRAIN_EXTRACTION_OUTPUT_DIR}/${ABIDE_VERSION}/${SITE}/${SUB_ID}/anat"
    ANAT_FILE_OUTPUT="${BET_OUTPUT_DIRECTORY}/${SUB_ID}_T1w"

    if [ -f "${ANAT_FILE_OUTPUT}.nii.gz" ]; then
        log "Subject already processed at \"${BET_OUTPUT_DIRECTORY}.nii.gz\", skipping..."
        continue
    fi

    mkdir -p $BET_OUTPUT_DIRECTORY

    bet $ANAT_FILE_INPUT $ANAT_FILE_OUTPUT \
        -f $BET_FRACTIONAL_INTENSITY_THRESHOLD \
        -g $BET_VERTICAL_GRADIENT_IN_FRACTIONAL_INTENSITY_THRESHOLD | tee -a "$LOGFILE"

    log "Done"
done < "${SUBJECTS_FILE}"


log ""
log "Finished running BET. Total subjects ${TOTAL_COUNT}. Output: ${BRAIN_EXTRACTION_OUTPUT_DIR}"
