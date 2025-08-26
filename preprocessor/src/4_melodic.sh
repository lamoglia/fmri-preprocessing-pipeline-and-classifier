#!/bin/bash
# This script runs MELODIC (GROUP ICA)
# References
# - https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/MELODIC(2f)FAQ.html
# - https://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/MELODIC.html
# The key output from the group MELODIC is the melodic_IC.nii.gz. This is a 4D image where each volume corresponds to an ICA component. 
# This melodic_IC.nii.gz can be used as a group level template (spatial basis) to feed into dual regression
#
# USAGE:
# ./4_melodic.sh subjects_experiment1.txt "/mnt/f/data/output/fsl/general/feat/FWHM-6.0_RR-4_DV-3_BBT-10" 25 concat "/mnt/f/data/output/fsl/general/melodic"
# Inputs: 
# - SUBJECTS_FILE_NAME - txt file containing subjects to be processed (no header)
# - FEAT OUTPUT DIR - directory used as output for FEAT (contains .ica directories)
# - MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER - dimensionality reduction into #num dimensions
# - MELODIC_APPROACH = concat (MIGP)/tica (tensor_ICA)
# - OUTPUT_DIR - Base output dir for melodic
#
# about 18min (72 subjects)
# 150 - 300MB (72 subjects)
# INPUT PARAMS #######################################################################
. ./utils.sh
SUBJECTS_FILE=${1}
#FEAT step output
FEAT_FILES_DIR=${2}

MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER=${3:-1}

MELODIC_APPROACH=${4:-"concat"}

OUTPUT_DIR=${5}

BET_FRACTIONAL_INTENSITY_THRESHOLD=${6}
#if output dir not set , show an error message and exit
if [ -z "$OUTPUT_DIR" ]; then
    log "Error: OUTPUT_DIR is required"
    exit 1
fi
#if BET_FRACTIONAL_INTENSITY_THRESHOLD is not set , show an error message and exit
if [ -z "$BET_FRACTIONAL_INTENSITY_THRESHOLD" ]; then
    log "Error: BET_FRACTIONAL_INTENSITY_THRESHOLD is required"
    exit 1
fi
#if output dir exists, show an error message and exit
if [ -d "$OUTPUT_DIR" ]; then
    log "Error: OUTPUT_DIR already exists: ${OUTPUT_DIR}"
    exit 1
fi
mkdir -p $OUTPUT_DIR

#if MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER is not a number >= 0 show an error message and exit
re='^[0-9]+$'
if ! [[ $MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER =~ $re ]] ; then
    log "Error: MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER must be a number >= 0 (currently $MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER)"
    exit 1
fi

#if MELODIC_APPROACH is not "tica" or "concat", show an error message and exit
if [[ "$MELODIC_APPROACH" != "tica" && "$MELODIC_APPROACH" != "concat" ]]; then
    log "Error: MELODIC_APPROACH must be either 'tica' or 'concat' (currently $MELODIC_APPROACH)"
    exit 1
fi

# FIXED PARAMETERS #######################################################################
BRAIN_MASK=MNI152_T1_2mm_brain_mask.nii.gz #fixed

# OTHER VARIABLES #######################################################################
GROUP_ICA_INPUT_FILE="${OUTPUT_DIR}/group_ica_input.txt"

rm -f $GROUP_ICA_INPUT_FILE

log "Starting MELODIC (group ICA)"
log "Params: DIMENSIONALITY_REDUCTION_PARAMETER: ${MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER}"
log "BET_FRACTIONAL_INTENSITY_THRESHOLD: ${BET_FRACTIONAL_INTENSITY_THRESHOLD}"
log "MELODIC_APPROACH: ${MELODIC_APPROACH}"
log "SUBJECTS_FILE: ${SUBJECTS_FILE}"
log ""

TOTAL_SUBJECTS_ON_SUBJECTS_FILE=$(grep -c . "$SUBJECTS_FILE")


log "Generating input file ${GROUP_ICA_INPUT_FILE}"

TOTAL_SUBJECTS_IN_INPUT_FILE=$(grep -c . "${SUBJECTS_FILE}")
CURRENT_COUNT=0
#line format
#abide_version,site,sub_id,group,age,sex,full_iq,tr_seconds,slice_timing_file,total_volumes,functional_fmri_file,anatomical_fmri_file,total_voxels
while read line; do
    CURRENT_COUNT=$((CURRENT_COUNT+1))

    ABIDE_VERSION=$(echo $line | cut -d ',' -f 1)
    SITE=$(echo $line | cut -d ',' -f 2)
    SUB_ID=$(echo $line | cut -d ',' -f 3)

    SUBJECT_ICA_DIR="${FEAT_FILES_DIR}/${ABIDE_VERSION}/${SITE}/${SUB_ID}.ica"
    FMRI_CLEAN_AND_STANDARIZED_TO_MNI="${SUBJECT_ICA_DIR}/filtered_func_data_clean_standard.nii.gz"

    #check if FMRI_CLEAN_AND_STANDARIZED_TO_MNI file exists
    if [ ! -f "$FMRI_CLEAN_AND_STANDARIZED_TO_MNI" ]; then
        log "ERROR: SKIPPING subject: FMRI_CLEAN_AND_STANDARIZED_TO_MNI not found: $FMRI_CLEAN_AND_STANDARIZED_TO_MNI"
        continue
    fi
    log "Including subject (${CURRENT_COUNT} of ${TOTAL_SUBJECTS_IN_INPUT_FILE}): $FMRI_CLEAN_AND_STANDARIZED_TO_MNI"
    echo "${FMRI_CLEAN_AND_STANDARIZED_TO_MNI}" >> $GROUP_ICA_INPUT_FILE

done < "${SUBJECTS_FILE}"

log "Done generating input file with ${TOTAL_SUBJECTS_ON_SUBJECTS_FILE} subjects at ${GROUP_ICA_INPUT_FILE}"

log "Running melodic (${TOTAL_SUBJECTS_ON_SUBJECTS_FILE} subjects)..."

#In ICA, the goal is to separate a multivariate signal (like fMRI time series) into independent components. There are two main approaches:
#Deflation-based ICA:
#    Components are estimated sequentially.
#    After finding one independent component, it's "deflated" (removed) from the data.
#    The process is repeated on the residual data to extract the next component.
#    Common in algorithms like FastICA (the default in MELODIC).
#Symmetric (parallel) ICA:
#    All components are estimated simultaneously.
#    Usually slower, but can give more stable results in some cases.
#Why it matters:
#    Reproducibility: Because deflation is sequential and depends on earlier components, small changes (like in preprocessing) can ripple through and affect later components.
#    Component Quality: Sometimes deflation may lead to less stable components compared to symmetric methods, especially when components are of similar strength.
# all NYU subjects use TR = 2
# --dimest        use specific dim. estimation technique: lap, bic, mdl, aic, mean (default: lap)
melodic -i "${GROUP_ICA_INPUT_FILE}" \
  -o "${OUTPUT_DIR}" \
  --nobet \
  --bgthreshold=${BET_FRACTIONAL_INTENSITY_THRESHOLD} \
  -a $MELODIC_APPROACH \
  -m "${FSLDIR}/data/standard/${BRAIN_MASK}" \
  --report \
  --tr=2 \
  --Oall \
  --dimest=lap \
  --nl=pow3 \
  -d $MELODIC_DIMENSIONALITY_REDUCTION_PARAMETER | tee -a "$LOGFILE"

log "Finished MELODIC (group ICA) with ${TOTAL_SUBJECTS_ON_SUBJECTS_FILE} subjects"
log "GROUP_ICA_INPUT_FILE (for dual regression): ${GROUP_ICA_INPUT_FILE}"
log "OUTPUT_DIR (for dual regression): ${OUTPUT_DIR}"