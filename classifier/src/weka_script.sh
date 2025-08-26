#!/bin/bash
# add the current date in format YYYY_MM_DD_HH_MM_SS to a variable
# weka CLI docs https://github.com/Waikato/weka-wiki/blob/master/docs/primer.md
. ./utils.sh

# read from first arg the experiment name,, if not set, show an error and exit
if [ -z "$4" ]
then
    log "Usage: ./${0} <experiment-input-dir> <experiment-output-dir> <fc-pc-fcpc> <cross-validation-folds> <classifier-optional> <featue-count-optional>"
    exit 1
fi 
EXPERIMENT_INPUT_DIR=$1
EXPERIMENT_OUTPUT_DIR=$2
CONNECTIVITY_TYPE=$3 #fc,pc or fcpc
CROSS_VALIDATION_FOLDS=$4
FEATURE_COUNT_OPTIONAL=$6

# check if CONNECTIVITY_TYPE is either "fc", "pc" or "fcpc"
if [ "$CONNECTIVITY_TYPE" != "fc" ] && [ "$CONNECTIVITY_TYPE" != "pc" ] && [ "$CONNECTIVITY_TYPE" != "fcpc" ]; then
    log "CONNECTIVITY_TYPE must be either 'fc', 'pc' or 'fcpc'."
    exit 1
fi

# if output dir exists, exit
if [ -d "$EXPERIMENT_OUTPUT_DIR/output_variations/${CONNECTIVITY_TYPE}" ]; then
    log "Output directory ${EXPERIMENT_OUTPUT_DIR}/output_variations/${CONNECTIVITY_TYPE} already exists."
    #exit 1
fi

NOW=$(date +"%Y_%m_%d_%H_%M_%S")

INPUT_VARIATIONS_DIR="${EXPERIMENT_OUTPUT_DIR}/input_variations"
OUTPUT_VARIATIONS_DIR="${EXPERIMENT_OUTPUT_DIR}/output_variations"
WEKA_TRAINING_DATA_DIR="${EXPERIMENT_OUTPUT_DIR}/training_data"

CONNECTIVITY_INPUT_VARIATIONS_DIR="${INPUT_VARIATIONS_DIR}/${CONNECTIVITY_TYPE}"
CONNECTIVITY_OUTPUT_VARIATIONS_DIR="${OUTPUT_VARIATIONS_DIR}/${CONNECTIVITY_TYPE}"

CONNECTIVITY_CSV_FILE="${EXPERIMENT_INPUT_DIR}/${CONNECTIVITY_TYPE}_training_data.csv"

CONNECTIVITY_FEATURE_COUNT=$(head -n 1 $CONNECTIVITY_CSV_FILE | grep -o "," | wc -l)
# subtract 1 from CONNECTIVITY_FEATURE_COUNT to remove sub_id (not to train with it)
CONNECTIVITY_FEATURE_COUNT=$((CONNECTIVITY_FEATURE_COUNT-1))

# Input dataset in ARFF format (will be generated from csv)
CONNECTIVITY_DATASET_ARFF="${WEKA_TRAINING_DATA_DIR}/${CONNECTIVITY_TYPE}_training_data.arff"

mkdir -p $CONNECTIVITY_INPUT_VARIATIONS_DIR
mkdir -p $CONNECTIVITY_OUTPUT_VARIATIONS_DIR
mkdir -p $WEKA_TRAINING_DATA_DIR

log "Experiment name: $EXPERIMENT_INPUT_DIR"
log "Experiment date: $NOW"

log $CONNECTIVITY_CSV_FILE
log "Converting CSV to ARFF..."
#https://weka.sourceforge.io/doc.dev/weka/core/converters/CSVLoader.html
java -cp ${WEKA_JAR_PATH} weka.core.converters.CSVLoader ${CONNECTIVITY_CSV_FILE} -N "last" -R "1-${CONNECTIVITY_FEATURE_COUNT}" > "$CONNECTIVITY_DATASET_ARFF"
log "Conversion complete."
log "" 

#need to install via weka package manager
# ClassificationViaClustering
# SysFor
# ForestPA
# RBFNetwork
# LibLINEAR
# discriminantAnalysis
# functionalTrees
# netlibNativeLinux

if [ -z "$5" ] || [ "$5" == "all" ]; then
    # List of Weka classifiers you want to test
    classifiers=(
        "weka.classifiers.bayes.NaiveBayes" #https://weka.sourceforge.io/doc.dev/weka/classifiers/bayes/NaiveBayes.html
        "weka.classifiers.functions.LDA" #https://weka.sourceforge.io/doc.packages/discriminantAnalysis/weka/classifiers/functions/LDA.html
        "weka.classifiers.functions.LibLINEAR" #https://weka.sourceforge.io/doc.stable/weka/classifiers/functions/LibLINEAR.html
        "weka.classifiers.functions.MultilayerPerceptron" #https://weka.sourceforge.io/doc.dev/weka/classifiers/functions/MultilayerPerceptron.html
        "weka.classifiers.functions.MultilayerPerceptron -H a,a"
        "weka.classifiers.functions.MultilayerPerceptron -H a,a,a"
        "weka.classifiers.functions.RBFClassifier" #https://weka.sourceforge.io/doc.packages/RBFNetwork/weka/classifiers/functions/RBFClassifier.html
        "weka.classifiers.functions.SGD" #https://weka.sourceforge.io/doc.dev/weka/classifiers/functions/SGD.html
        "weka.classifiers.functions.SMO" #https://weka.sourceforge.io/doc.dev/weka/classifiers/functions/SMO.html
        "weka.classifiers.meta.ClassificationViaClustering" #https://weka.sourceforge.io/doc.stable/weka/classifiers/meta/ClassificationViaClustering.html
        "weka.classifiers.trees.FT" #https://weka.sourceforge.io/doc.packages/functionalTrees/weka/classifiers/trees/FT.html
        "weka.classifiers.trees.HoeffdingTree" #https://weka.sourceforge.io/doc.dev/weka/classifiers/trees/HoeffdingTree.html
        "weka.classifiers.trees.SysFor" #https://github.com/zislam/SysFor/blob/master/src/weka/classifiers/trees/SysFor.java
    )
else
    classifiers=("$5")
fi

# PARTIAL+FULL CORRELATION FEATURES
# run classifier for each variation with a subset of features
if [ -z "$FEATURE_COUNT_OPTIONAL" ] || [ "$FEATURE_COUNT_OPTIONAL" == "all" ];
then
    FEATURE_COUNT_VARIATIONS=$(seq 1 $CONNECTIVITY_FEATURE_COUNT)
else
    FEATURE_COUNT_VARIATIONS=$FEATURE_COUNT_OPTIONAL
fi

for i in $FEATURE_COUNT_VARIATIONS;
do
    #set variable zero_padded with i-1 with 0 padding
    ZERO_PADDED_LAST_FEATURE_INDEX=$(printf "%02d" $((i)))
    INPUT_ARFF_FILE="${CONNECTIVITY_INPUT_VARIATIONS_DIR}/feat_1-${ZERO_PADDED_LAST_FEATURE_INDEX}.arff"
    # Remove the attribute with index i from the dataset
    log "Keeping only attributes 1-$i on dataset..."
    java -cp $WEKA_JAR_PATH weka.filters.unsupervised.attribute.Remove -V -R "1-$i,last" -i $CONNECTIVITY_DATASET_ARFF -o "${INPUT_ARFF_FILE}"

    # Loop through each classifier and run it on the dataset
    for classifier in "${classifiers[@]}"; do
        #get the name after the last "." in the classifier
        CLASSIFIER_LAST_NAME=$(echo $classifier | grep -oP '[^\.]+$')
        #handle classifier optional parameters
        CLASSIFIER_LAST_NAME=$(echo $CLASSIFIER_LAST_NAME | sed 's/ /_/g'| sed 's/,/_/g'| sed 's/\-/_/g')

        OUTPUT_TXT_FILE="${CONNECTIVITY_OUTPUT_VARIATIONS_DIR}/results_${CLASSIFIER_LAST_NAME}_feat_1-${ZERO_PADDED_LAST_FEATURE_INDEX}_${CROSS_VALIDATION_FOLDS}-fold.txt"
        log "Running classifier: $classifier ($CLASSIFIER_LAST_NAME)"
        log "java -cp $WEKA_JAR_PATH weka.Run $classifier -t "${INPUT_ARFF_FILE}" -x ${CROSS_VALIDATION_FOLDS} -v"
        java -cp $WEKA_JAR_PATH weka.Run $classifier -t "${INPUT_ARFF_FILE}" -x ${CROSS_VALIDATION_FOLDS} -v >> $OUTPUT_TXT_FILE 
        log "Results saved to $OUTPUT_TXT_FILE"
    done
    log ""
done

log "Done."
log ""