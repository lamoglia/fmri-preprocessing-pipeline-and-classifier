#!/bin/bash -e
. ./utils.sh

# Run all steps for a full preprocessing + Timeseries extraction

# Usage:
# ./preprocess.sh <experiment_config_file> <output_dir>
# ex.
# ./preprocess.sh experiment1_config.txt /experiments/dir
EXPERIMENT_CONFIG_FILE=${1}

# output directories for intemediary processing
# WORK_BASE_DIR="/mnt/f/data/output/fsl/general-v3"
if [[ -z "${EXPERIMENT_CONFIG_FILE}" ]]; then
  log "EXPERIMENT_CONFIG_FILE env var undefined. Exiting."
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

EXPERIMENT_CONFIG_FILE="${EXPERIMENT_DEFINITIONS_BASE_DIR}/${EXPERIMENT_CONFIG_FILE}"
#read the file and set these variables. if any of them is not found , print an error and exit
#removes carriage returns (they will be there if created with windows)
sed -i 's/\r//g' ${EXPERIMENT_CONFIG_FILE}
source ${EXPERIMENT_CONFIG_FILE} || { log "Error: Unable to read configuration file ${EXPERIMENT_CONFIG_FILE}"; exit 1; }

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

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        log "Error: $var is not set"
        exit 1
    fi
done

SUBJECTS_FULL_FILE_PATH="${EXPERIMENT_DEFINITIONS_BASE_DIR}/${SUBJECTS}"

if [ ! -f "$SUBJECTS_FULL_FILE_PATH" ]; then
    log "Error: SUBJECTS file not found: ${SUBJECTS_FULL_FILE_PATH}"
    exit 1
fi

#SET THE NUMBER OF LINES OF SUBJECTS_FILE file to var TOTAL_COUNT
TOTAL_SUBJECT_COUNT=$(grep -c . "$SUBJECTS_FULL_FILE_PATH")
TOTAL_SUBJECT_COUNT_VALIDATE=$(wc -l < "$SUBJECTS_FULL_FILE_PATH")

# if TOTAL_COUNT and TOTAL_COUNT_VALIDATE are different, show an error message and exit
if [ "$TOTAL_SUBJECT_COUNT" -ne "$TOTAL_SUBJECT_COUNT_VALIDATE" ]; then
    log "Error: SUBJECTS file has a different number of lines than expected: ${TOTAL_SUBJECT_COUNT} != ${TOTAL_SUBJECT_COUNT_VALIDATE}"
    log "Maybe missing an empty line at the end of the subjects file?"
    exit 1
fi

#get the string before the last '.' in the file name
SUBJ_FILE_NAME=$(basename ${SUBJECTS_FULL_FILE_PATH%.*})

#Build a standarized experiment name based on paramaters
#e.g. subjects_group1_dim0_fwhm6_resamp4_fixthr30

NOW=$(date +"%Y%m%d_%H%M%S")
#EXPERIMENT_NAME="${NOW}_${SUBJ_FILE_NAME}_dim${MELODIC_DIMENSIONALITY_REDUCTION}_fwhm${FEAT_SPATIAL_SMOOTHING_FWHM}_resamp${FEAT_RESAMPLING_RESOLUTION_MM}_fixthr${FIX_THRESHOLD_PARAMETER}_bbt${FEAT_BRAIN_BACKGROUND_THRESHOLD}_ma${MELODIC_APPROACH}_rm${FIX_REGRESS_MOTION}"
EXPERIMENT_NAME="${NOW}_${SUBJ_FILE_NAME}"

FEAT_BASE_DIR="${WORK_BASE_DIR}/${EXPERIMENT_NAME}/feat"
BET_BASE_DIR="${WORK_BASE_DIR}/${EXPERIMENT_NAME}/bet"
MELODIC_BASE_DIR="${WORK_BASE_DIR}/${EXPERIMENT_NAME}/melodic"
DUAL_REGRESSION_BASE_DIR="${WORK_BASE_DIR}/${EXPERIMENT_NAME}/dual-regression"

CURRENT_EXPERIMENT_OUTPUT_BASE_DIR="${OUTPUT_BASE_DIR}/${EXPERIMENT_NAME}"

# check if CURRENT_EXPERIMENT_OUTPUT_BASE_DIR exists and if so, print a message and exit
if [ -d "$CURRENT_EXPERIMENT_OUTPUT_BASE_DIR" ]; then
    log "Experiment directory already exists: ${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}. Skipping..."
    exit 1
fi

mkdir -p ${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}

log "Starting experiment ${EXPERIMENT_CONFIG_FILE}"
log "Experiment name ${EXPERIMENT_NAME}"

cp "${SUBJECTS_FULL_FILE_PATH}" "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}"
cp "${EXPERIMENT_CONFIG_FILE}" "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/experiment_definition.txt"

log ""
log "FSL"
log $(fslversion)
log "Params:"
for var in "${required_vars[@]}"; do
    log "$var=${!var}"
done
log ""

########################################
### BET
### https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/BET.html
########################################

BET_INSTANCE_OUTPUT_DIR="${BET_BASE_DIR}/FIT-${BET_FRACTIONAL_INTENSITY_THRESHOLD}_G-${BET_VERTICAL_GRADIENT_THRESHOLD}"

log "Starting BET"
# ~1sec +3MB
./1_bet.sh "${SUBJECTS_FULL_FILE_PATH}" \
    "$BET_INSTANCE_OUTPUT_DIR" \
    $BET_FRACTIONAL_INTENSITY_THRESHOLD \
    $BET_VERTICAL_GRADIENT_THRESHOLD

log "Finished BET"
log "BET output: ${BET_INSTANCE_OUTPUT_DIR}"

########################################
### FEAT 
### https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FEAT.html
### https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FEAT(2f)UserGuide.html
### https://open.win.ox.ac.uk/pages/fslcourse/practicals/feat1/index.html
### https://open.win.ox.ac.uk/pages/fslcourse/practicals/feat2/index.html
########################################

log ""
log "Starting FEAT"
FEAT_INSTANCE_OUTPUT_DIR="${FEAT_BASE_DIR}/FWHM-${FEAT_SPATIAL_SMOOTHING_FWHM}_RR-${FEAT_RESAMPLING_RESOLUTION_MM}_DV-${FEAT_DELETE_VOLUMES}_BBT-${FEAT_BRAIN_BACKGROUND_THRESHOLD}"

# ~10min +170MB
./2_feat.sh "${SUBJECTS_FULL_FILE_PATH}" \
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
### https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FIX(2f)UserGuide.html
### https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FIX.html
########################################

log ""
log "Starting FIX"
# ~5min +100MB
./3_fix.sh "${SUBJECTS_FULL_FILE_PATH}" \
    "${FEAT_INSTANCE_OUTPUT_DIR}" \
    "${FIX_THRESHOLD_PARAMETER}" \
    ${FIX_REGRESS_MOTION}

log "Finished FIX"
log "FEAT output (same as FEAT)"

########################################
### MELODIC
### Multivariate Exploratory Linear Optimized Decomposition into Independent Components
### https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/MELODIC.html
########################################

log ""
log "Starting MELODIC"

MELODIC_INSTANCE_OUTPUT_DIR="${MELODIC_BASE_DIR}/${EXPERIMENT_NAME}"
# 18min 150-300MB (72 subjects)
./4_melodic.sh "${SUBJECTS_FULL_FILE_PATH}" \
    "${FEAT_INSTANCE_OUTPUT_DIR}" \
    ${MELODIC_DIMENSIONALITY_REDUCTION} \
    ${MELODIC_APPROACH} \
    "${MELODIC_INSTANCE_OUTPUT_DIR}" \
    "${BET_FRACTIONAL_INTENSITY_THRESHOLD}"

log "Finished MELODIC" 
log "MELODIC output: ${MELODIC_INSTANCE_OUTPUT_DIR}"

########################################
### DUAL REGRESSION
### https://fsl.fmrib.ox.ac.uk/fslcourse/2019_Beijing/lectures/ICA_and_resting_state/ICA_and_Dual_Regression.pdf
########################################

log ""
log "Starting DUAL REGRESSION"

#DUAL_REGRESSION_OUTPUT_DIR="${DUAL_REGRESSION_BASE_DIR}/${EXPERIMENT_NAME}"
#file with full path to each subject filtered_func_data_clean_standard.nii.gz
GROUP_ICA_INPUT_FILE="${MELODIC_INSTANCE_OUTPUT_DIR}/group_ica_input.txt"

# 11h ~4GB (72 subjects)
./5_dual-regression.sh \
    "${DUAL_REGRESSION_BASE_DIR}" \
    "${MELODIC_INSTANCE_OUTPUT_DIR}/melodic_IC" \
    "${GROUP_ICA_INPUT_FILE}" \
    "${DR_NORMALIZE}"

log "Finished DUAL REGRESSION"

log "DUAL REGRESSION output: ${DUAL_REGRESSION_BASE_DIR}"

log "Copying dual regression to output dir"
mkdir -p "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/dual_regression"
cp ${DUAL_REGRESSION_BASE_DIR}/fsl-dual-regression/dr_stage1* "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/dual_regression/"
cp ${DUAL_REGRESSION_BASE_DIR}/fsl-dual-regression/mask.nii.gz "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/dual_regression/mask.nii.gz"
log "Copying dual melodic IC mask to output dir"
mkdir -p "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/melodic"
cp "${MELODIC_INSTANCE_OUTPUT_DIR}/melodic_IC.nii.gz" "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/melodic/melodic_IC.nii.gz"
cp "${FEAT_INSTANCE_OUTPUT_DIR}/design.fsf" "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/design.fsf"

if [ -f "${LOGFILE}" ]; then
    log "Copying logs to output dir"
    cp ${LOGFILE} "${CURRENT_EXPERIMENT_OUTPUT_BASE_DIR}/"
fi

log ""
log "Finished experiment"