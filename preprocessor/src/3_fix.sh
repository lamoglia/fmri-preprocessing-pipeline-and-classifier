#!/bin/sh
# This script runs FIX
# Fix removes noise, fixes motion and indicates which signals are noise and which are not (fix4melview)
# ./3_fix.sh subjects_experiment1.txt "/mnt/f/data/output/fsl/general/feat/FWHM-6.0_RR-4_DV-3_BBT-10" "/mnt/f/data/output/fsl/general/fix"
# Inputs: 
# - SUBJECTS_FILE_NAME - txt file containing subjects to be processed (no header)
# - FEAT OUTPUT DIR
# 
# about 5 min per subject
# generates few files inside ica dir : ~100MB/subject
#
# outputs:
# Main output filtered_func_data_clean.nii.gz e fix4melview_Standard_thr30.txt
# ix4melview_‹training data›_thr‹threshold›.txt

# https://fsl.fmrib.ox.ac.uk/fsl/docs/#/resting_state/fix
# INPUT PARAMS #######################################################################
. ./utils.sh
SUBJECTS_FILE=${1}

#FEAT step output
FEAT_FILES_DIR=${2}
# In the FIX command-line call, the number 30 is a threshold between 0 and 100 - a lower value will result in more conservative clean-up 
# (i.e. less chance of good components being removed), whereas a higher value will result in more aggressive clean up.
FIX_THRESHOLD_PARAMETER=${4:-30}
#regress motion parameters from the data, in addition to regressing noise components. (on/off 0/1)
FIX_REGRESS_MOTION=${5:-1}

# FIXED PARAMETERS #######################################################################
# OTHER MODELS: ${FSLDIR}/pkgs/fsl-pyfix-0.8.1-py_0/site-packages/pyfix/resources/models/*pyfix_model
# this model classifies the signals as noise or not
#The following built-in models can be used for classification:
# - HCP25_hp2000
# - HCP7T_hp2000
# - HCP_Style_Single_Multirun_Dedrift
# - NHP_HCP_Macaque
# - NHP_HCP_MacaqueCyno
# - Standard
# - UKBiobank
# - WhII_MB6
# - WhII_Standard
TRAINED_MODEL="Standard" 

#can change based on FIX installation
PYFIX_VERSION="fsl-pyfix-0.9.0-py_0"

# OTHER VARIABLES #######################################################################

#SET THE NUMBER OF LINES OF SUBJECTS_FILE file to var TOTAL_COUNT
TOTAL_COUNT=$(grep -c . "$SUBJECTS_FILE")

log "Starting FIX"
log "Params: fix threshold: ${FIX_THRESHOLD_PARAMETER}, regress motion: ${FIX_REGRESS_MOTION}, trained model: ${TRAINED_MODEL}"

CURRENT_COUNT=0
#line format
#abide_version,site,sub_id,group,age,sex,full_iq,tr_seconds,slice_timing_file,total_volumes,functional_fmri_file,anatomical_fmri_file,total_voxels
while read line; do
  CURRENT_COUNT=$((CURRENT_COUNT+1))

  ABIDE_VERSION=$(echo $line | cut -d ',' -f 1)
  SITE=$(echo $line | cut -d ',' -f 2)
  SUB_ID=$(echo $line | cut -d ',' -f 3)


  log "Running FIX $CURRENT_COUNT of $TOTAL_COUNT: $ABIDE_VERSION - $SITE - $SUB_ID"

  SUBJECT_FEAT_OUTPUT="${FEAT_FILES_DIR}/${ABIDE_VERSION}/${SITE}/${SUB_ID}.ica"

  #check directory exists SUBJECT_FEAT_OUTPUT
  if [ ! -d "$SUBJECT_FEAT_OUTPUT" ]; then
    log "ERROR: SKIPPING fix for subject: ICA Directory not found: $SUBJECT_FEAT_OUTPUT"
    continue
  fi

  # Rodar FIX for Automatic IC classification and noise removal
  # Main output filtered_func_data_clean.nii.gz e fix4melview_Standard_thr30.txt
  # fix4melview_‹training data›_thr‹threshold›.txt
  # Interesting ouput: fix4melview_‹training data›_thr‹threshold›.txt eg fix4melview_Standard_thr30.txt

  log "Generating ${SUBJECT_FEAT_OUTPUT}/filtered_func_data_clean.nii.gz"
  log "Generating ${SUBJECT_FEAT_OUTPUT}/filtered_func_data_clean_vn.nii.gz"
  log "Generating ${SUBJECT_FEAT_OUTPUT}/fix4melview_${TRAINED_MODEL}_thr${FIX_THRESHOLD_PARAMETER}.txt"
  
  if [ $FIX_REGRESS_MOTION -eq 1 ]; then
    log "Running FIX with threshold ${FIX_THRESHOLD_PARAMETER} and motion regression enabled"

    # -m optionally also cleanup motion confounds, with highpass filtering of motion confounds controlled by -h
    # if -h is omitted, fix will use the highpass cutoff in a design.fsf
    fix "${SUBJECT_FEAT_OUTPUT}" \
      "${FSLDIR}/pkgs/${PYFIX_VERSION}/site-packages/pyfix/resources/models/${TRAINED_MODEL}.pyfix_model" \
      $FIX_THRESHOLD_PARAMETER -m | tee -a "$LOGFILE"
  else
    log "Running FIX threshold ${FIX_THRESHOLD_PARAMETER} and regress motion disabled"
    fix "${SUBJECT_FEAT_OUTPUT}" \
      "${FSLDIR}/pkgs/${PYFIX_VERSION}/site-packages/pyfix/resources/models/${TRAINED_MODEL}.pyfix_model" \
      $FIX_THRESHOLD_PARAMETER | tee -a "$LOGFILE"
  fi

  log "done: ${SUBJECT_MELODIC_OUTPUT}.ica/filtered_func_data_clean.nii.gz"
  log ""
done < "${SUBJECTS_FILE}"

CURRENT_COUNT=0
#line format
#abide_version,site,sub_id,group,age,sex,full_iq,tr_seconds,slice_timing_file,total_volumes,functional_fmri_file,anatomical_fmri_file,total_voxels
while read line; do
  CURRENT_COUNT=$((CURRENT_COUNT+1))

  ABIDE_VERSION=$(echo $line | cut -d ',' -f 1)
  SITE=$(echo $line | cut -d ',' -f 2)
  SUB_ID=$(echo $line | cut -d ',' -f 3)

  log "Running applywarp $CURRENT_COUNT of $TOTAL_COUNT: $ABIDE_VERSION - $SITE - $SUB_ID"

  SUBJECT_FEAT_OUTPUT="${FEAT_FILES_DIR}/${ABIDE_VERSION}/${SITE}/${SUB_ID}.ica"

  #check directory exists SUBJECT_FEAT_OUTPUT
  if [ ! -d "$SUBJECT_FEAT_OUTPUT" ]; then
    log "ERROR: SKIPPING applywarp for subject: ICA Directory not found: $SUBJECT_FEAT_OUTPUT"
    continue
  fi

  #remove processed files if existent
  rm -f "${SUBJECT_FEAT_OUTPUT}/filtered_func_data_clean_standard.nii.gz"

  # Register to MNI space
  # The output of this script will be a standard space clean preprocessed 4D resting image for each subject
  #(filtered_func_data_clean_standard.nii.gz) as well as a txt file (inputlist_new.txt), which contains a 
  # list of the filepaths to the filtered_func_data_clean_standard.nii.gz for each subject. This list is 
  # necessary for running the group ICA and the dual regression.

  applywarp \
    --in="${SUBJECT_FEAT_OUTPUT}/filtered_func_data_clean.nii.gz" \
    --ref="${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz" \
    --warp="${SUBJECT_FEAT_OUTPUT}/reg/highres2standard_warp.nii.gz" \
    --premat="${SUBJECT_FEAT_OUTPUT}/reg/example_func2highres.mat" \
    --out="${SUBJECT_FEAT_OUTPUT}/filtered_func_data_clean_standard.nii.gz" | tee -a "$LOGFILE"

done < "${SUBJECTS_FILE}"


log "Finished Running FIX and applywarp"