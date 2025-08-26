import pandas as pd
HIGH_PRECISION_SUMMARY_FILE="/home/lamoglia/projetos/unifei/correlation-code/classifier/data/weka_results/summary_high_precision_only.csv"
NEW_EXPERIMENT_DIR="/home/lamoglia/projetos/unifei/correlation-code/classifier/data/new_experiment_out"
GENERATE_ALL=True

#read SUMMARY_FILE_PATH csv
summary = pd.read_csv(HIGH_PRECISION_SUMMARY_FILE, sep=",", header=0, engine='python')

#discard first 7 columns
summary = summary.iloc[:,7:]


BET_FRACTIONAL_INTENSITY_THRESHOLD_VALUES=[0.3]
BET_VERTICAL_GRADIENT_THRESHOLD_VALUES=[0]
# não maior que 4 mm, que é o tamanho do voxel FEAT_RESAMPLING_RESOLUTION_MM_VALUES
FEAT_SPATIAL_SMOOTHING_FWHM_VALUES = [0,2,4]
FEAT_RESAMPLING_RESOLUTION_MM_VALUES = [4]
FEAT_DELETE_VOLUMES_VALUES = [3]
FEAT_BRAIN_BACKGROUND_THRESHOLD_VALUES = [9,10,11]
MELODIC_DIMENSIONALITY_REDUCTION_VALUES = [0,25]
MELODIC_APPROACH_VALUES = ["concat"]
FIX_THRESHOLD_PARAMETER_VALUES = [0,28,29,30,31,32]
FIX_REGRESS_MOTION_VALUES=[1]
DR_NORMALIZE_VALUES=[1]

SUBJECTS_FULL_PATH='/home/lamoglia/projects/fsl/experiments/group1.txt'

#summary has these columns: BET_FRACTIONAL_INTENSITY_THRESHOLD,BET_VERTICAL_GRADIENT_THRESHOLD,FEAT_SPATIAL_SMOOTHING_FWHM,FEAT_RESAMPLING_RESOLUTION_MM,FEAT_DELETE_VOLUMES,FEAT_BRAIN_BACKGROUND_THRESHOLD,MELODIC_DIMENSIONALITY_REDUCTION,MELODIC_APPROACH,FIX_THRESHOLD_PARAMETER,FIX_REGRESS_MOTION,DR_NORMALIZE
#iterate over and generate variations not present in the summary based on the values above
generated_count=0
for fwhm in FEAT_SPATIAL_SMOOTHING_FWHM_VALUES:
    for bbt in FEAT_BRAIN_BACKGROUND_THRESHOLD_VALUES:
        for dr in MELODIC_DIMENSIONALITY_REDUCTION_VALUES:
            for approach in MELODIC_APPROACH_VALUES:
                for threshold in FIX_THRESHOLD_PARAMETER_VALUES:
                    for regress in FIX_REGRESS_MOTION_VALUES:
                        if GENERATE_ALL or not ((summary['FEAT_SPATIAL_SMOOTHING_FWHM'] == fwhm) & (summary['MELODIC_DIMENSIONALITY_REDUCTION'] == dr) & (summary['MELODIC_APPROACH'] == approach) & (summary['FIX_THRESHOLD_PARAMETER'] == threshold) & (summary['FIX_REGRESS_MOTION'] == regress) & (summary['FEAT_BRAIN_BACKGROUND_THRESHOLD'] == bbt)).any():
                            #create a file named group1_dim in NEW_EXPERIMENT_DIR
                            #new_experiment_file_name = NEW_EXPERIMENT_DIR + "/group1_dim" + str(dr) + "_fwhm" + str(fwhm) + "_resamp"+ str(FEAT_RESAMPLING_RESOLUTION_MM_VALUES[0]) + "_fixthr" + str(threshold)
                            
                            new_experiment_file_name = NEW_EXPERIMENT_DIR + "/v2_group1_dim" + str(dr) + "_fwhm" + str(fwhm) + "_resamp"+ str(FEAT_RESAMPLING_RESOLUTION_MM_VALUES[0]) + "_fixthr" + str(threshold) + "_bbt" + str(bbt) + "_ma" + approach + "_rm" + str(regress) + ".txt"

                            #create the file and write content to it
                            with open(new_experiment_file_name, 'w') as f:
                                f.write("# BET\n")
                                f.write("BET_FRACTIONAL_INTENSITY_THRESHOLD=" + str(BET_FRACTIONAL_INTENSITY_THRESHOLD_VALUES[0]) + "\n")
                                f.write("BET_VERTICAL_GRADIENT_THRESHOLD=" + str(BET_VERTICAL_GRADIENT_THRESHOLD_VALUES[0]) + "\n")
                                f.write("# FEAT\n")
                                f.write("FEAT_SPATIAL_SMOOTHING_FWHM=" + str(fwhm) + "\n")
                                f.write("FEAT_RESAMPLING_RESOLUTION_MM=" + str(FEAT_RESAMPLING_RESOLUTION_MM_VALUES[0]) + "\n")
                                f.write("FEAT_DELETE_VOLUMES=" + str(FEAT_DELETE_VOLUMES_VALUES[0]) + "\n")
                                f.write("FEAT_BRAIN_BACKGROUND_THRESHOLD=" + str(bbt) + "\n")
                                f.write("# MELODIC\n")
                                f.write("MELODIC_DIMENSIONALITY_REDUCTION=" + str(dr) + "\n")
                                f.write("MELODIC_APPROACH=" + approach + "\n")
                                f.write("# Subject selection file\n")
                                f.write("SUBJECTS=\""+str(SUBJECTS_FULL_PATH)+"\"\n")
                                f.write("# FIX\n")
                                f.write("FIX_THRESHOLD_PARAMETER=" + str(threshold) + "\n")
                                f.write("FIX_REGRESS_MOTION=" + str(regress) + "\n")
                                f.write("# DUAL REGRESSION\n")
                                f.write("DR_NORMALIZE=" + str(DR_NORMALIZE_VALUES[0]) + "\n")
                            generated_count += 1

print("Generated " + str(generated_count) + " new experiments")
