#!/bin/bash
# this script summarizes results of weka
. ./utils.sh

if [ -z "$1" ]; then # input dir
    log "ERROR: Missing PREPROCESSED_EXPERIMENT_DIR"
    exit 1
else 
    PREPROCESSED_EXPERIMENT_DIR="$1"
fi
if [ -z "$2" ]; then # input dir
    log "ERROR: Missing WEKA_RESULTS_DIR"
    exit 1
else 
    WEKA_RESULTS_DIR="$2"
fi
if [ -z "$3" ]; then # output dir
    log "ERROR: Missing SUMMARY_OUTPUT_DIR"
    exit 1
else 
    SUMMARY_OUTPUT_DIR="$3"
fi

SUMMARY_FILE_CSV="${SUMMARY_OUTPUT_DIR}/summary.csv"
SUMMARY_FILE_CSV_TMP="${SUMMARY_OUTPUT_DIR}/summary_tmp.csv"
CONFUSION_TRUE_FILE_CSV_TMP="${SUMMARY_OUTPUT_DIR}/confusion_true_tmp.csv"
CONFUSION_FALSE_FILE_CSV_TMP="${SUMMARY_OUTPUT_DIR}/confusion_false_tmp.csv"
HIGH_PRECISION_SUMMARY_FILE_CSV="${SUMMARY_OUTPUT_DIR}/summary_high_precision_only.csv"
# summarize results
 
echo "feature_group,classifier" > "${SUMMARY_FILE_CSV_TMP}"

find ${WEKA_RESULTS_DIR}/output_variations/*/ -type f | \
    sed "s#${WEKA_RESULTS_DIR}/output_variations/\([^\/]\+\)/results_\([^\.]\+\)\.txt.*#\1,\2#g" \
    >> "${SUMMARY_FILE_CSV_TMP}"

echo "feature_group,classifier,true_positives,false_negatives" > "${CONFUSION_TRUE_FILE_CSV_TMP}"
# true positives, false negatives.
find ${WEKA_RESULTS_DIR}/output_variations/*/ -type f | xargs grep --with-filename "= True" | \
    sed "s#${WEKA_RESULTS_DIR}/output_variations/\([^\/]\+\)/results_\([^\.]\+\)\.txt:\s*\([0-9]\+\)\s\+\([0-9]\+\).*#\1,\2,\3,\4#g" \
    >> "${CONFUSION_TRUE_FILE_CSV_TMP}"

echo "feature_group,classifier,false_positives,true_negatives" > "${CONFUSION_FALSE_FILE_CSV_TMP}"
# false positives, true negatives.
find ${WEKA_RESULTS_DIR}/output_variations/*/ -type f | xargs grep --with-filename "= False" | \
    sed "s#${WEKA_RESULTS_DIR}/output_variations/\([^\/]\+\)/results_\([^\.]\+\)\.txt:\s*\([0-9]\+\)\s\+\([0-9]\+\).*#\1,\2,\3,\4#g" \
    >> "${CONFUSION_FALSE_FILE_CSV_TMP}"

echo "feature_group,classifier,features,true_positives,false_negatives,false_positives,true_negatives,BET_FRACTIONAL_INTENSITY_THRESHOLD,BET_VERTICAL_GRADIENT_THRESHOLD,FEAT_SPATIAL_SMOOTHING_FWHM,FEAT_RESAMPLING_RESOLUTION_MM,FEAT_DELETE_VOLUMES,FEAT_BRAIN_BACKGROUND_THRESHOLD,MELODIC_DIMENSIONALITY_REDUCTION,EFFECTIVE_MELODIC_DIMENSIONALITY_REDUCTION,FEATURES_SELECTED,MELODIC_APPROACH,FIX_THRESHOLD_PARAMETER,FIX_REGRESS_MOTION,DR_NORMALIZE" > "${SUMMARY_FILE_CSV}"

for line in $(tail -n +2 ${SUMMARY_FILE_CSV_TMP}); do
    IFS=',' read -r -a fields <<< "${line}"

    EXPERIMENT_DEFINITION_FILE="${PREPROCESSED_EXPERIMENT_DIR}/experiment_definition.txt"
    DUAL_REGRESSION_SAMPLE_FILE="${PREPROCESSED_EXPERIMENT_DIR}/dual_regression/dr_stage1_subject00000.txt"

    TRAINING_INPUT_DIR="${WEKA_RESULTS_DIR}/input_variations/${fields[0]}/"
    # check if EXPERIMENT_DEFINITION_FILE exist
    if [ ! -f ${EXPERIMENT_DEFINITION_FILE} ]; then
        echo "Experiment definition file not found: ${EXPERIMENT_DEFINITION_FILE}"
        echo "SUMMARY_FILE_CSV_TMP: ${SUMMARY_FILE_CSV_TMP}"
        echo "Exiting..."
        exit
    fi
    source ${EXPERIMENT_DEFINITION_FILE}

    TRUE_POSITIVES_FALSE_NEGATIVES=`grep "${fields[0]},${fields[1]}" "${CONFUSION_TRUE_FILE_CSV_TMP}" | sed 's#[^,]\+,[^,]\+,\([0-9]\+\),\([0-9]\+\)#\1,\2#g'`
    FALSE_POSITIVES_TRUE_NEGATIVES=`grep "${fields[0]},${fields[1]}" "${CONFUSION_FALSE_FILE_CSV_TMP}" | sed 's#[^,]\+,[^,]\+,\([0-9]\+\),\([0-9]\+\)#\1,\2#g'`

    #if MELODIC_DIMENSIONALITY_REDUCTION = 0
    if [ ${MELODIC_DIMENSIONALITY_REDUCTION} -eq 0 ]; then
        EFFECTIVE_MELODIC_DIMENSIONALITY_REDUCTION=`head -n 1 ${DUAL_REGRESSION_SAMPLE_FILE} | wc -w`
    else
        EFFECTIVE_MELODIC_DIMENSIONALITY_REDUCTION=${MELODIC_DIMENSIONALITY_REDUCTION}
    fi

    EFFECTIVE_FEATURES_SELECTED=`ls -1 ${TRAINING_INPUT_DIR} | wc -l`

    echo "${fields[0]},${fields[1]},${TRUE_POSITIVES_FALSE_NEGATIVES},${FALSE_POSITIVES_TRUE_NEGATIVES},${BET_FRACTIONAL_INTENSITY_THRESHOLD},${BET_VERTICAL_GRADIENT_THRESHOLD},${FEAT_SPATIAL_SMOOTHING_FWHM},${FEAT_RESAMPLING_RESOLUTION_MM},${FEAT_DELETE_VOLUMES},${FEAT_BRAIN_BACKGROUND_THRESHOLD},${MELODIC_DIMENSIONALITY_REDUCTION},${EFFECTIVE_MELODIC_DIMENSIONALITY_REDUCTION},${EFFECTIVE_FEATURES_SELECTED},${MELODIC_APPROACH},${FIX_THRESHOLD_PARAMETER:-30},${FIX_REGRESS_MOTION:-1},${DR_NORMALIZE:-1}" >> "${SUMMARY_FILE_CSV}"

    # unset all variables so they wont persist in the next loop iteration
    unset DR_NORMALIZE
    unset FIX_REGRESS_MOTION
    unset FIX_THRESHOLD_PARAMETER
    unset MELODIC_APPROACH
    unset MELODIC_DIMENSIONALITY_REDUCTION
    unset FEAT_BRAIN_BACKGROUND_THRESHOLD
    unset FEAT_DELETE_VOLUMES
    unset FEAT_RESAMPLING_RESOLUTION_MM
    unset FEAT_SPATIAL_SMOOTHING_FWHM
    unset BET_VERTICAL_GRADIENT_THRESHOLD
    unset BET_FRACTIONAL_INTENSITY_THRESHOLD

done

# split the classifier column creating a features column
sed -i 's/_feat_\([0-9]\+\)-\([0-9]\+\),/,\1-\2,/g' ${SUMMARY_FILE_CSV}
log "Summary file created at ${SUMMARY_FILE_CSV}"
rm ${SUMMARY_FILE_CSV_TMP}
rm ${CONFUSION_FALSE_FILE_CSV_TMP}
rm ${CONFUSION_TRUE_FILE_CSV_TMP}

uv run summary_processor.py ${SUMMARY_FILE_CSV} ${HIGH_PRECISION_SUMMARY_FILE_CSV}