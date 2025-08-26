#!/bin/bash
# run all steps for a full preprocessing + Timeseries extraction for subjects not in the original group
# using the same configurations of a previously preprocessed batch.
# USAGE:
# ./external.sh <reference-experiment-dir> ext_subjects.csv 
# ./external.sh 20250316_203437_72_participants ext_subjects.csv 
. ./utils.sh

REFERENCE_EXPERIMENT_OUTPUT_DIR_RELATIVE=${1}

REFERENCE_EXPERIMENT_OUTPUT_DIR_FULL="${OUTPUT_BASE_DIR}/${REFERENCE_EXPERIMENT_OUTPUT_DIR_RELATIVE}"

REFERENCE_EXPERIMENT_CONFIG_FILE="${REFERENCE_EXPERIMENT_OUTPUT_DIR_FULL}/experiment_definition.txt"
EXTERNAL_SUBJECTS_FILE_RELATIVE=${2}

EXTERNAL_SUBJECTS_FILE_FULL="${EXPERIMENT_DEFINITIONS_BASE_DIR}/${EXTERNAL_SUBJECTS_FILE_RELATIVE}"

if [ ! -d "$REFERENCE_EXPERIMENT_OUTPUT_DIR_FULL" ]; then
    log "Error: REFERENCE_EXPERIMENT_OUTPUT_DIR_FULL is not a directory: ${REFERENCE_EXPERIMENT_OUTPUT_DIR_FULL}"
    exit 1
fi
if [ ! -f "$REFERENCE_EXPERIMENT_CONFIG_FILE" ]; then
    log "Error: REFERENCE_EXPERIMENT_CONFIG_FILE file not found: ${REFERENCE_EXPERIMENT_CONFIG_FILE}"
    exit 1
fi
if [ ! -f "$EXTERNAL_SUBJECTS_FILE_FULL" ]; then
    log "Error: EXTERNAL_SUBJECTS_FILE_FULL file not found: ${EXTERNAL_SUBJECTS_FILE_FULL}"
    exit 1
fi

if [[ -z "${WORK_BASE_DIR}" ]]; then
  log "WORK_BASE_DIR env var undefined. Exiting."
  exit 1
fi
if [[ -z "${OUTPUT_BASE_DIR}" ]]; then
  log "OUTPUT_BASE_DIR env var undefined. Exiting."
  exit 1
fi
# check if OUTPUT_BASE_DIR is a directory
if [ ! -d "$OUTPUT_BASE_DIR" ]; then
    log "Error: OUTPUT_BASE_DIR is not a directory: ${OUTPUT_BASE_DIR}"
    exit 1
fi


#read the file and set these variables. if any of them is not found,
#print an error and exit
sed -i 's/\r//g' ${REFERENCE_EXPERIMENT_CONFIG_FILE}
source ${REFERENCE_EXPERIMENT_CONFIG_FILE} || { log "Error: Unable to read configuration file ${REFERENCE_EXPERIMENT_CONFIG_FILE}"; exit 1; }

required_vars=(
    BET_FRACTIONAL_INTENSITY_THRESHOLD
    BET_VERTICAL_GRADIENT_THRESHOLD
    FEAT_SPATIAL_SMOOTHING_FWHM
    FEAT_RESAMPLING_RESOLUTION_MM
    FEAT_DELETE_VOLUMES
    FEAT_BRAIN_BACKGROUND_THRESHOLD
    MELODIC_DIMENSIONALITY_REDUCTION
    MELODIC_APPROACH
    SUBJECTS
    FIX_THRESHOLD_PARAMETER
    FIX_REGRESS_MOTION
    DR_NORMALIZE
)

#############################
# VALIDATIONS

#get the string before the last '.' in the file name
SUBJ_FILE_NAME=$(basename ${EXTERNAL_SUBJECTS_FILE_FULL%.*})

NOW=$(date +"%Y%m%d_%H%M%S")
EXPERIMENT_NAME="ext_${NOW}_${SUBJ_FILE_NAME}"

# output directories for intemediary processing
FEAT_BASE_DIR="${WORK_BASE_DIR}/${EXPERIMENT_NAME}/feat"
BET_BASE_DIR="${WORK_BASE_DIR}/${EXPERIMENT_NAME}/bet"
DUAL_REGRESSION_BASE_DIR="${WORK_BASE_DIR}/${EXPERIMENT_NAME}/dual-regression"


CURRENT_EXPERIMENT_OUTPUT_BASE_DIR="${OUTPUT_BASE_DIR}/${EXPERIMENT_NAME}"

# check if CURRENT_EXPERIMENT_OUTPUT_BASE_DIR exists and if so, print a message and exit
if [ -d "$CURRENT_EXPERIMENT_OUTPUT_BASE_DIR" ]; then
    log "Experiment directory already exists: ${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}. Skipping..."
    exit 1
fi

mkdir -p ${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        log "Error: $var is not set"
        exit 1
    fi
done

REFERENCE_EXP_SUBJECTS_FULL_FILE_PATH="${EXPERIMENT_DEFINITIONS_BASE_DIR}/${SUBJECTS}"

if [ ! -f "$REFERENCE_EXP_SUBJECTS_FULL_FILE_PATH" ]; then
    log "Error: REFERENCE_EXP_SUBJECTS_FULL_FILE_PATH file not found: ${REFERENCE_EXP_SUBJECTS_FULL_FILE_PATH}"
    exit 1
fi

#SET THE NUMBER OF LINES OF EXTERNAL_SUBJECTS_FILE_FULL file to var TOTAL_COUNT
TOTAL_SUBJECT_COUNT=$(grep -c . "$REFERENCE_EXP_SUBJECTS_FULL_FILE_PATH")
TOTAL_SUBJECT_COUNT_VALIDATE=$(wc -l < "$REFERENCE_EXP_SUBJECTS_FULL_FILE_PATH")

# if TOTAL_COUNT and TOTAL_COUNT_VALIDATE are different, show an error message and exit
if [ "$TOTAL_SUBJECT_COUNT" -ne "$TOTAL_SUBJECT_COUNT_VALIDATE" ]; then
    log "Error: SUBJECTS file has a different number of lines than expected: ${TOTAL_SUBJECT_COUNT} != ${TOTAL_SUBJECT_COUNT_VALIDATE}"
    log "Maybe missing an empty line at the end of the subjects file?"
    exit 1
fi

#SET THE NUMBER OF LINES OF EXTERNAL_SUBJECTS_FILE_FULL file to var TOTAL_COUNT
TOTAL_SUBJECT_COUNT=$(grep -c . "$EXTERNAL_SUBJECTS_FILE_FULL")
TOTAL_SUBJECT_COUNT_VALIDATE=$(wc -l < "$EXTERNAL_SUBJECTS_FILE_FULL")

# if TOTAL_COUNT and TOTAL_COUNT_VALIDATE are different, show an error message and exit
if [ "$TOTAL_SUBJECT_COUNT" -ne "$TOTAL_SUBJECT_COUNT_VALIDATE" ]; then
    log "Error: EXTERNAL_SUBJECTS_FILE_FULL file has a different number of lines than expected: ${TOTAL_SUBJECT_COUNT} != ${TOTAL_SUBJECT_COUNT_VALIDATE}"
    log "Maybe missing an empty line at the end of the EXTERNAL_SUBJECTS_FILE_FULL file?"
    exit 1
fi

SUBJ_FILE_NAME=$(basename ${SUBJECTS%.*})

log "Starting experiment ${REFERENCE_EXPERIMENT_CONFIG_FILE}"
log "Experiment name ${EXPERIMENT_NAME}"

cp "${EXTERNAL_SUBJECTS_FILE_FULL}" "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}"
cp "${REFERENCE_EXPERIMENT_CONFIG_FILE}" "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/experiment_definition.txt"

log ""
log "FSL version"
log $(fslversion)
log "Params:"
for var in "${required_vars[@]}"; do
    log "$var=${!var}"
done
log ""
log "Reference experiment output dir: ${REFERENCE_EXPERIMENT_OUTPUT_DIR_FULL}"
log "External subjects file: ${EXTERNAL_SUBJECTS_FILE_FULL}"
log ""
########################################
### BET
########################################

log "Starting BET"
BET_INSTANCE_OUTPUT_DIR="${BET_BASE_DIR}/FIT-${BET_FRACTIONAL_INTENSITY_THRESHOLD}_G-${BET_VERTICAL_GRADIENT_THRESHOLD}"
# ~1sec +3MB
./1_bet.sh "${EXTERNAL_SUBJECTS_FILE_FULL}" \
    "$BET_INSTANCE_OUTPUT_DIR" \
    $BET_FRACTIONAL_INTENSITY_THRESHOLD \
    $BET_VERTICAL_GRADIENT_THRESHOLD

log "Finished BET"
log "BET output: ${BET_INSTANCE_OUTPUT_DIR}"

########################################
### FEAT
########################################

log ""
log "Starting FEAT"
FEAT_INSTANCE_OUTPUT_DIR="${FEAT_BASE_DIR}/FWHM-${FEAT_SPATIAL_SMOOTHING_FWHM}_RR-${FEAT_RESAMPLING_RESOLUTION_MM}_DV-${FEAT_DELETE_VOLUMES}_BBT-${FEAT_BRAIN_BACKGROUND_THRESHOLD}"

# ~10min +170MB
./2_feat.sh "${EXTERNAL_SUBJECTS_FILE_FULL}" \
    "${BET_INSTANCE_OUTPUT_DIR}" \
    ${FEAT_SPATIAL_SMOOTHING_FWHM} \
    ${FEAT_RESAMPLING_RESOLUTION_MM} \
    ${FEAT_DELETE_VOLUMES} \
    ${FEAT_BRAIN_BACKGROUND_THRESHOLD} \
    "${FEAT_INSTANCE_OUTPUT_DIR}"


log "Finished FEAT"
log "FEAT output: ${FEAT_INSTANCE_OUTPUT_DIR}"

########################################
### FIX
########################################

log ""
log "Starting FIX"
# ~5min +100MB
./3_fix.sh "${EXTERNAL_SUBJECTS_FILE_FULL}" \
    "${FEAT_INSTANCE_OUTPUT_DIR}" \
    "${FIX_THRESHOLD_PARAMETER}" \
    ${FIX_REGRESS_MOTION}

log "Finished FIX"
log "FEAT output (same as FEAT)"

########################################
### MELODIC
########################################

# skip melodic as it is a group phase


########################################
### DUAL REGRESSION
### https://fsl.fmrib.ox.ac.uk/fslcourse/2019_Beijing/lectures/ICA_and_resting_state/ICA_and_Dual_Regression.pdf
########################################

log ""
log "Starting DUAL REGRESSION"

GROUP_ICA_INPUT_FILE="${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/group_ica_input.txt"

find ${FEAT_INSTANCE_OUTPUT_DIR} -name "filtered_func_data_clean_standard.nii.gz" > "${GROUP_ICA_INPUT_FILE}"

MELODIC_INSTANCE_OUTPUT_DIR="${REFERENCE_EXPERIMENT_OUTPUT_DIR_FULL}/melodic/"

# 11h ~4GB (72 subjects)
./5_dual-regression.sh \
    "${DUAL_REGRESSION_BASE_DIR}" \
    "${MELODIC_INSTANCE_OUTPUT_DIR}/melodic_IC" \
    "${GROUP_ICA_INPUT_FILE}" \
    "${DR_NORMALIZE}"

log "Finished DUAL REGRESSION"

log "DUAL REGRESSION output: ${DUAL_REGRESSION_BASE_DIR}"

log "Copying dual_regression output to experiment dir"
mkdir -p "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/dual_regression"
cp ${DUAL_REGRESSION_BASE_DIR}/fsl-dual-regression/dr_stage1* "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/dual_regression/"

cp ${REFERENCE_EXP_SUBJECTS_FULL_FILE_PATH} "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/${SUBJECTS}"
cp "${FEAT_INSTANCE_OUTPUT_DIR}/design.fsf" "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/design.fsf"

if [ -f "${LOGFILE}" ]; then
    log "Copying logs to experiment dir"
    cp ${LOGFILE} "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/"
fi

log ""
log "Finished experiment"