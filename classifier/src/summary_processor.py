import pandas as pd
import sys

#read SUMMARY_FILE_PATH from the first argument
SUMMARY_FILE_PATH = sys.argv[1]
PROCESSED_SUMMARY_FILE_PATH = sys.argv[2]

# read the csv file into a dataframe
# this dataset has these columns: experiment,feature_group,classifier,features,true_positives,false_negatives,false_positives,true_negatives,BET_FRACTIONAL_INTENSITY_THRESHOLD,BET_VERTICAL_GRADIENT_THRESHOLD,FEAT_SPATIAL_SMOOTHING_FWHM,FEAT_RESAMPLING_RESOLUTION_MM,FEAT_DELETE_VOLUMES,FEAT_BRAIN_BACKGROUND_THRESHOLD,MELODIC_DIMENSIONALITY_REDUCTION,MELODIC_APPROACH,FIX_THRESHOLD_PARAMETER,FIX_REGRESS_MOTION,DR_NORMALIZE
summary = pd.read_csv(SUMMARY_FILE_PATH, sep=",", header=0, engine='python')

# if the clumn accuracy is not present, create it
if 'accuracy' not in summary.columns:
    # add a column "accuracy"
    summary['accuracy'] = (summary['true_positives'] + summary['true_negatives']) / (summary['true_positives'] + summary['true_negatives'] + summary['false_positives'] + summary['false_negatives'])
    # add a column "specificity"
    summary['specificity'] = summary['true_negatives'] / (summary['true_negatives'] + summary['false_positives'])
    # add a column "sensitivity" (AKA RECALL)
    summary['sensitivity'] = summary['true_positives'] / (summary['true_positives'] + summary['false_negatives'])
    # add a column "precision"
    summary['precision'] = summary['true_positives'] / (summary['true_positives'] + summary['false_positives'])
    # add a column "f_measure"
    summary['f_measure'] = 2 * (summary['precision'] * summary['sensitivity']) / (summary['precision'] + summary['sensitivity'])

    #sort by accuracy, specificity, sensitivity and precision
    summary = summary.sort_values(by=['accuracy', 'specificity', 'sensitivity', 'precision'], ascending=False)
    # write it back to the csv file
    summary.to_csv(SUMMARY_FILE_PATH, index=False)

# create a new column uniq with the concatenation of columns BET_FRACTIONAL_INTENSITY_THRESHOLD,BET_VERTICAL_GRADIENT_THRESHOLD,FEAT_SPATIAL_SMOOTHING_FWHM,FEAT_RESAMPLING_RESOLUTION_MM,FEAT_DELETE_VOLUMES,FEAT_BRAIN_BACKGROUND_THRESHOLD,MELODIC_DIMENSIONALITY_REDUCTION,MELODIC_APPROACH,FIX_THRESHOLD_PARAMETER,FIX_REGRESS_MOTION,DR_NORMALIZE, separating its values by a # 
summary['uniq'] = summary[['BET_FRACTIONAL_INTENSITY_THRESHOLD', 'BET_VERTICAL_GRADIENT_THRESHOLD', 'FEAT_SPATIAL_SMOOTHING_FWHM', 'FEAT_RESAMPLING_RESOLUTION_MM', 'FEAT_DELETE_VOLUMES', 'FEAT_BRAIN_BACKGROUND_THRESHOLD', 'MELODIC_DIMENSIONALITY_REDUCTION', 'MELODIC_APPROACH', 'FIX_THRESHOLD_PARAMETER', 'FIX_REGRESS_MOTION', 'DR_NORMALIZE']].apply(lambda x: '#'.join(x.astype(str)), axis=1)

# remove rows with precision equals ?
summary = summary[summary.precision != "?"]

# for each experiment, keep only one row with the highest precision. if there is a tie, keep all
# the rows with the highest precision
summary['accuracy'] = summary['accuracy'].astype(float)
summary['precision'] = summary['precision'].astype(float)
summary['sensitivity'] = summary['sensitivity'].astype(float)
summary['f_measure'] = summary['f_measure'].astype(float)
# group by experiment and keep the row with the highest precision
#summary = summary.loc[summary.groupby('uniq')['accuracy'].idxmax()]

# remove the uniq column
summary = summary.drop(columns=['uniq'])

# sort by precision, specificity and sensitivity
summary = summary.sort_values(by=['accuracy', 'specificity', 'sensitivity', 'precision'], ascending=False)

# save the processed summary to a new csv file
summary.to_csv(PROCESSED_SUMMARY_FILE_PATH, index=False)
