#!/bin/bash
# This script runs FEAT
# ./2_feat.sh subjects.txt BRAIN_EXTRACTED_DIR FWHM RR DV BBT OUTPUT_DIR
# "./2_feat.sh subjects_experiment1.txt "/mnt/f/data/output/fsl/general/bet/FIT-0.3_G-0" 6.0 4 3 10 "/mnt/f/data/output/fsl/general/feat"
# Inputs: 
# - SUBJECTS_FILE_NAME - txt file containing subjects to be processed (no header)
# - BRAIN_EXTRACTED_DIR - directory used as output for BET
# - SPATIAL_SMOOTHING_FWHM_PARAMETER=6.0
# - RESAMPLING_RESOLUTION_MM_PARAMETER=4
# - DELETE_VOLUMES_PARAMETER=3
# - BRAIN_BACKGROUND_THRESHOLD_PARAMETER=10
# - OUTPUT_DIR

# OUTPUT: about 174MB output dir (.ica) per subject (10 minutes)
# https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FEAT(2f)UserGuide.html
# - removes first x volumes
# - Full first-level analysis
# - Registration
# - normalization 
# - motion correction
# INPUT PARAMS #######################################################################
. ./utils.sh
SUBJECTS_FILE_DEFAULT="subjects.txt"
SUBJECTS_FILE=${1:-$SUBJECTS_FILE_DEFAULT}

#previous step output
BRAIN_EXTRACTED_DIR=${2}

SPATIAL_SMOOTHING_FWHM_PARAMETER=${3}
RESAMPLING_RESOLUTION_MM_PARAMETER=${4}
DELETE_VOLUMES_PARAMETER=${5}
BRAIN_BACKGROUND_THRESHOLD_PARAMETER=${6}
FEAT_OUTPUT_DIR=${7}

if ! [[ $SPATIAL_SMOOTHING_FWHM_PARAMETER =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  log "SPATIAL_SMOOTHING_FWHM_PARAMETER must be a number" >&2; exit 1
fi

if ! [[ $RESAMPLING_RESOLUTION_MM_PARAMETER =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  log "RESAMPLING_RESOLUTION_MM_PARAMETER must be a number" >&2; exit 1
fi

if ! [[ $DELETE_VOLUMES_PARAMETER =~ ^[0-9]+$ ]]; then
  log "DELETE_VOLUMES_PARAMETER must be an integer" >&2; exit 1
fi

# OTHER VARIABLES #######################################################################
FEAT_FSF_TEMPLATE_FILE="${FEAT_OUTPUT_DIR}/design.fsf" #renamed from MELODIC_FSF_TEMPLATE_FILE

mkdir -p $FEAT_OUTPUT_DIR

cp design.fsf ${FEAT_FSF_TEMPLATE_FILE}

#SET THE NUMBER OF LINES OF SUBJECTS_FILE file to var TOTAL_COUNT
TOTAL_COUNT=$(grep -c . "$SUBJECTS_FILE")

log "Running FEAT"
log "Params:"

CURRENT_COUNT=0
#line format
#abide_version,site,sub_id,group,age,sex,full_iq,tr_seconds,slice_timing_file,total_volumes,functional_fmri_file,anatomical_fmri_file,total_voxels
while read line; do
  CURRENT_COUNT=$((CURRENT_COUNT+1))

  ABIDE_VERSION=$(echo $line | cut -d ',' -f 1)
  SITE=$(echo $line | cut -d ',' -f 2)
  SUB_ID=$(echo $line | cut -d ',' -f 3)
  TR_SECONDS=$(echo $line | cut -d ',' -f 8)
  SLICE_ORDER_FILE_NAME=$(echo $line | cut -d ',' -f 9)
  TOTAL_VOLUMES=$(echo $line | cut -d ',' -f 10)
  FUNCTIONAL_FMRI_FILE=$(echo $line | cut -d ',' -f 11)
  TOTAL_VOXELS=$(echo $line | cut -d ',' -f 13)

  log "Running FEAT $CURRENT_COUNT of $TOTAL_COUNT: $ABIDE_VERSION - $SITE - $SUB_ID"

  #remove the .nii.gz extension from FUNCTIONAL_FMRI_FILE
  FUNCTIONAL_FMRI_FILE_WO_EXTENSION=$(echo $FUNCTIONAL_FMRI_FILE | cut -d '.' -f 1)

  #check if SLICE_ORDER_FILE_NAME is empty
  if [ -z "${SLICE_ORDER_FILE_NAME}" ]; then
    log "Warn: SLICE_ORDER_FILE_NAME is empty"
    SLICE_ORDER_FILE_FULL_PATH=""
    log "Wont use slice order correction"
    SLICE_TIMING_CORRECTION_PARAMETER=0 #fixed 0 (no Slice timing correction)
  else
    SLICE_ORDER_FILE_FULL_PATH="${SLICE_ORDER_FILES_DIR}/${SLICE_ORDER_FILE_NAME}"
    #check if SLICE_ORDER_FILE_FULL_PATH exists
    if [ ! -f "${SLICE_ORDER_FILE_FULL_PATH}" ]; then
      log "Warn: SLICE_ORDER_FILE not found: ${SLICE_ORDER_FILE_FULL_PATH}"
      SLICE_ORDER_FILE_FULL_PATH=""
      log "Wont use slice order correction"
      SLICE_TIMING_CORRECTION_PARAMETER=0 #fixed 0 (no Slice timing correction)
    else
      log "Using slice order correction"
      SLICE_TIMING_CORRECTION_PARAMETER=3 #fixed 3 (Use slice order file)
    fi
  fi

  BET_STRUCTURAL_FILE="${BRAIN_EXTRACTED_DIR}/${ABIDE_VERSION}/${SITE}/${SUB_ID}/anat/${SUB_ID}_T1w"
  SUBJECT_FEAT_OUTPUT="${FEAT_OUTPUT_DIR}/${ABIDE_VERSION}/${SITE}/${SUB_ID}"
  SUBJECT_FEAT_FSF_CONFIG_FILE="${FEAT_OUTPUT_DIR}/feat-${ABIDE_VERSION}-${SITE}-${SUB_ID}.fsf"

  if [ -d "${SUBJECT_FEAT_OUTPUT}.ica" ]; then
      log "Subject already processed at \"${SUBJECT_FEAT_OUTPUT}.ica\", skipping..."
      continue
  fi
  
  mkdir -p "${FEAT_OUTPUT_DIR}/${ABIDE_VERSION}/${SITE}"

  log "Creating FEAT fsf config file ${SUBJECT_FEAT_FSF_CONFIG_FILE}..."
  #copy fsf file template
  cp ${FEAT_FSF_TEMPLATE_FILE} ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  
  sed -i "s|##{OUTPUT_DIR}##|${SUBJECT_FEAT_OUTPUT}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{4D_FILE}##|${BIDS_INPUT_BASE_DIR}/${FUNCTIONAL_FMRI_FILE_WO_EXTENSION}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{STRUCTURAL_FILE}##|${BET_STRUCTURAL_FILE}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{FSLDIR}##|${FSLDIR}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{TR}##|${TR_SECONDS}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{TOTAL_VOLUMES}##|${TOTAL_VOLUMES}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{DELETE_VOLUMES}##|${DELETE_VOLUMES_PARAMETER}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{BRAIN_BACKGROUND_THRESHOLD}##|${BRAIN_BACKGROUND_THRESHOLD_PARAMETER}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{SLICE_TIMING_CORRECTION}##|${SLICE_TIMING_CORRECTION_PARAMETER}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{SLICE_TIMING_FILE}##|${SLICE_ORDER_FILE_FULL_PATH}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{SPATIAL_SMOOTHING_FWHM}##|${SPATIAL_SMOOTHING_FWHM_PARAMETER}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{TOTAL_VOXELS}##|${TOTAL_VOXELS}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}
  sed -i "s|##{RESAMPLING_RESOLUTION_MM}##|${RESAMPLING_RESOLUTION_MM_PARAMETER}|g" ${SUBJECT_FEAT_FSF_CONFIG_FILE}

  # Extrair IC
  # https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FEAT.html
  log "Running FEAT..."
  feat ${SUBJECT_FEAT_FSF_CONFIG_FILE} | tee -a "$LOGFILE"
  log "Done."

done < "${SUBJECTS_FILE}"
log "Finished Running FEAT"
log "Output at ${FEAT_OUTPUT_DIR}"