#!/bin/bash
# ./automation experiment_name <fc/pc/fcpc> <classifier> <feature-count>
# or try to test all possibilities
# ./automation 

# Example:
# ./automation.sh \
#    20250316_203437_72_participants \
#    fcpc \
#    "weka.classifiers.functions.MultilayerPerceptron -H a,a" \
#    28 

# this script automates: feature extraction, feature selection, training and summarizing
. ./utils.sh

# from env OUTPUT_BASE_DIR

if [ -z "$1" ]; then
    log "ERROR: Missing experiment_dir_name"
    exit 1
else 
    EXPERIMENT_DIR_NAME="$1"
fi

if [ -z "$2" ]; then
    FEATURE_TYPE="all"
else 
    FEATURE_TYPE="$2"
fi

if [ -z "$3" ]; then
    CLASSIFIER="all"
else 
    CLASSIFIER="$3"
fi

if [ -z "$4" ]; then
    FEATURE_COUNT="all"
else 
    FEATURE_COUNT="$4"
fi

PREPROCESSED_EXPERIMENT_DIR="${PREPROCESSED_OUTPUT_DIR}/${EXPERIMENT_DIR_NAME}"
DUAL_REGRESSION_SOURCE_DIR="${PREPROCESSED_EXPERIMENT_DIR}/dual_regression"
#check if EXPERIMENT_DIR_NAME directory exists
if [ ! -d "${DUAL_REGRESSION_SOURCE_DIR}" ]; then
    log "ERROR: dual regression dir not found: ${DUAL_REGRESSION_SOURCE_DIR}"
    exit 1
fi

now=$(date +"%Y%m%d_%H%M%S")

DUAL_REGRESSION_BASE_DIR="${OUTPUT_BASE_DIR}/${EXPERIMENT_DIR_NAME}/${now}/dual_regression_copy"
TRAINING_INPUT_BASE_DIR="${OUTPUT_BASE_DIR}/${EXPERIMENT_DIR_NAME}/${now}/training_input"
WEKA_RESULTS_DIR="${OUTPUT_BASE_DIR}/${EXPERIMENT_DIR_NAME}/${now}/weka_results"
SUMMARY_OUTPUT_DIR="${OUTPUT_BASE_DIR}/${EXPERIMENT_DIR_NAME}/${now}/summary"

mkdir -p ${DUAL_REGRESSION_BASE_DIR}
mkdir -p ${TRAINING_INPUT_BASE_DIR}
mkdir -p ${WEKA_RESULTS_DIR}
mkdir -p ${SUMMARY_OUTPUT_DIR}

cp -R "${DUAL_REGRESSION_SOURCE_DIR}/." ${DUAL_REGRESSION_BASE_DIR}
#remove all files without .txt extension from DUAL_REGRESSION_BASE_DIR
find ${DUAL_REGRESSION_BASE_DIR} -type f ! -name "*.txt" -exec rm -f {} \;
# turn dual regression raw output in comma separated csv
sed -i 's/  /,/g' ${DUAL_REGRESSION_BASE_DIR}/*.txt
sed -i 's/,$//g' ${DUAL_REGRESSION_BASE_DIR}/*.txt

EXPERIMENT_DEFINITION_FILE="${PREPROCESSED_OUTPUT_DIR}/${EXPERIMENT_DIR_NAME}/experiment_definition.txt"
#read field SUBJECTS form EXPERIMENT_DEFINITION_FILE (source it)
source ${EXPERIMENT_DEFINITION_FILE}
#if SUBJECTS is not defined, throw an error and exit
if [ -z "${SUBJECTS}" ]; then
    log "ERROR: SUBJECTS is not defined in ${EXPERIMENT_DEFINITION_FILE} Exiting..."
    exit 1
fi

EXPERIMENT_SUBJECTS_FILE_NAME=$(basename ${SUBJECTS})

# need to switch between original set and external set
# check if EXPERIMENT_DIR_NAME variable starts with "ext_"
if [[ "${EXPERIMENT_DIR_NAME}" == ext_* ]]; then
    # if it does, set the SUBJECTS_FILE to the external set
    SUBJECTS_FILE="${PREPROCESSED_OUTPUT_DIR}/${EXPERIMENT_DIR_NAME}/external_participants.txt"
else
    # if it doesn't, set the SUBJECTS_FILE to the original set
    SUBJECTS_FILE="${PREPROCESSED_OUTPUT_DIR}/${EXPERIMENT_DIR_NAME}/${EXPERIMENT_SUBJECTS_FILE_NAME}"
fi

SUBJECT_COUNT=$(wc -l < ${SUBJECTS_FILE})

if [ -z "$5" ]; then
    #count the number of lines in SUBJECTS_FILE
    CROSS_VALIDATION_FOLDS=$SUBJECT_COUNT
else 
    CROSS_VALIDATION_FOLDS="$5"
fi

#check if CROSS_VALIDATION_FOLDS is greater than subject count
if [ "$CROSS_VALIDATION_FOLDS" -gt "$SUBJECT_COUNT" ]; then
    log "ERROR: CROSS_VALIDATION_FOLDS (${CROSS_VALIDATION_FOLDS}) is greater than SUBJECT_COUNT (${SUBJECT_COUNT}). Exiting..."
    exit 1
fi

log "Will perform cross-validation with ${CROSS_VALIDATION_FOLDS} folds"

uv run feature_extraction_selection.py ${DUAL_REGRESSION_BASE_DIR} ${SUBJECTS_FILE} ${TRAINING_INPUT_BASE_DIR}

# if FEATURE_TYPE is "fcpc" or "all" prit hello world
if [ "${FEATURE_TYPE}" == "fcpc" ] || [ "${FEATURE_TYPE}" == "all" ]; then
    ./weka_script.sh ${TRAINING_INPUT_BASE_DIR} ${WEKA_RESULTS_DIR} fcpc "${CROSS_VALIDATION_FOLDS}" "${CLASSIFIER}" "${FEATURE_COUNT}"
fi

if [ "${FEATURE_TYPE}" == "fc" ] || [ "${FEATURE_TYPE}" == "all" ]; then
    ./weka_script.sh ${TRAINING_INPUT_BASE_DIR} ${WEKA_RESULTS_DIR} fc "${CROSS_VALIDATION_FOLDS}" "${CLASSIFIER}" "${FEATURE_COUNT}"
fi

if [ "${FEATURE_TYPE}" == "pc" ] || [ "${FEATURE_TYPE}" == "all" ]; then
    ./weka_script.sh ${TRAINING_INPUT_BASE_DIR} ${WEKA_RESULTS_DIR} pc "${CROSS_VALIDATION_FOLDS}" "${CLASSIFIER}" "${FEATURE_COUNT}"
fi

# summarize results
./result_processor.sh ${PREPROCESSED_EXPERIMENT_DIR} ${WEKA_RESULTS_DIR} ${SUMMARY_OUTPUT_DIR}