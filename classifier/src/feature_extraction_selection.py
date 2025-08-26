import sys
import numpy as np
import pandas as pd
import os

from utils import (
    anderson_darling_test,
    create_subject_feature_df,
    generate_feature_matrix_result,
    get_feature_count,
    get_full_correlation_matrix,
    get_partial_correlation_matrix,
    get_upper_tri,
    t_test_select_features,
    create_subject_feature_combined_df,
)


#read first argument from script call
# get the names of all files in /home/lamoglia, in alhpabetical order
dual_regression_dir=sys.argv[1]# "classifier/data/in/group1_dim0"
subjects_file_path=sys.argv[2]#"data/in/subjects_group1.txt"
target_dir=sys.argv[3]

# print parameters
print("\nStarting feature_extraction_selection.py...")
print(f"dual_regression_dir: {dual_regression_dir}")
print(f"subjects_file_path: {subjects_file_path}")
print(f"target_dir: {target_dir}")

os.makedirs(target_dir, exist_ok=True)

dr_files = os.listdir(dual_regression_dir)
dr_files.sort()

#replace "  " with "," on all dr_files
for file in dr_files:
    os.system(f"sed -i 's/  /,/g' {dual_regression_dir}/{file}")
    os.system(f"sed -i 's/,$//g' {dual_regression_dir}/{file}")


# read "/home/lamoglia/projetos/unifei/correlation-code/data/group_ica_input.csv" as csv, first line is the header
all_subjects = pd.read_csv(subjects_file_path, sep=",", header=None, engine='python')

# if dr_files length is different from all_subjects length, print error and exit
if len(dr_files) != len(all_subjects):
    print(f"Error: dr_files length ({len(dr_files)}) is different from all_subjects length ({len(all_subjects)})")
    print(dual_regression_dir)
    print()
    sys.exit(1)

#print length of the subjects
all_subjects["dr_result"] = dr_files
all_subjects["fc_upper_tri"] = np.empty((len(all_subjects), 0)).tolist()
all_subjects["pc_upper_tri"] = np.empty((len(all_subjects), 0)).tolist()

all_subjects.columns=["abide_version","site","sub_id","group","age","sex","full_iq","tr_seconds","slice_timing_file","total_volumes","functional_fmri_file","anatomical_fmri_file","total_voxels", "dr_result","fc_upper_tri","pc_upper_tri" ]
#add a column is_asd and set to true if group=="ASD"
all_subjects["is_asd"]=all_subjects["group"].apply(lambda x: 1 if x=="ASD" else 0)

#drop columns abide_version, site, slice_timing_file, functional_fmri_file, anatomical_fmri_file
all_subjects.drop(columns=["abide_version","site","group","age","sex","full_iq","tr_seconds","slice_timing_file","total_volumes","functional_fmri_file","anatomical_fmri_file","total_voxels"], inplace=True)
# asd_subjects = all_subjects[all_subjects['is_asd'] == 1]
# control_subjects = all_subjects[all_subjects['is_asd'] == 0]

#feature count is needed for sizing the correlation matrix (not all of them are 25x25 dim parameter may vary on preprocessing)
experiment_feature_count = -1

for index, row in all_subjects.iterrows():
    subject_dual_regression_file = dual_regression_dir+"/"+row["dr_result"]

    if experiment_feature_count == -1:
        experiment_feature_count = get_feature_count(subject_dual_regression_file)
        print (f"Feature count: {experiment_feature_count}")
        
    pc = get_partial_correlation_matrix(subject_dual_regression_file)
    fc = get_full_correlation_matrix(subject_dual_regression_file)
    # print correlation matrix to file, if subject is_asd set title to PC - subjectid - ASD, else set title to PC - subjectid - Control

    # plot_correlation_matrix_to_file(pc, "Partial Correlation " + row['subject'] + " " + category, f"{generated_file_path}/correlation_matrix/{row['subject']}_{category}_pc.jpg")
    # plot_correlation_matrix_to_file(fc, "Full Correlation " + row['subject'] + " " + category, f"{generated_file_path}/correlation_matrix/row['subject']}_{category}_fc.jpg")

    # get upper tri
    fc_upper_tri = get_upper_tri(fc)
    pc_upper_tri = get_upper_tri(pc)

    # add fc_upper_tri to a new column on all_subjects
    all_subjects.at[index, "fc_upper_tri"] = fc_upper_tri
    all_subjects.at[index, "pc_upper_tri"] = pc_upper_tri

# get values from all_subjects['pc_upper_tri'] as an array
pc_upper_tris = np.array(all_subjects["pc_upper_tri"].to_list())  # 72x300
fc_upper_tris = np.array(all_subjects["fc_upper_tri"].to_list())  # 72x300

print()
print("--[FULL CORRELATION]----------------------------")
# Executar Anderson-Darling test para ver se a distribuição é normal em cada feature
print("Anderson-Darling test for features (p-value < 5%):")
fc_normal_features, fc_non_normal_features = anderson_darling_test(fc_upper_tris)
print(f"  - Number of normal features: {len(fc_normal_features)}")
print(f"  - Number of non-normal features: {len(fc_non_normal_features)}")

# Usarei somente as features com distribuição normal
# T-test to check whether the mean correlation values of each feature differ significantly between ASD and non-ASD groups.

fc_p_values = t_test_select_features(all_subjects, fc_upper_tris)  # 72x300 -> 300

fc_feature_extraction = generate_feature_matrix_result(fc_p_values, fc_normal_features, experiment_feature_count)

# filter the lines from fc_feature_extraction where p_value < 0.05 and is_normal is 1.0
fc_feature_extraction_selected = fc_feature_extraction[
    (fc_feature_extraction["p_value"].astype(float) < 0.05) & (fc_feature_extraction["is_normal"].astype(float) == 1.0)
]
fc_feature_extraction_selected = fc_feature_extraction_selected.sort_values(by="p_value")
fc_feature_extraction_selected.drop(columns=["is_normal"], inplace=True)

print("Selected features (p-value < 0.05 and is_normal = True):")
#print(fc_feature_extraction_selected.to_string(index=False))
distinct_features = np.unique(
    np.concatenate(
        (fc_feature_extraction_selected["feature_x"].to_numpy(), fc_feature_extraction_selected["feature_y"].to_numpy())
    )
)
print("Distinct features (x/y): ")
print(distinct_features)

print()
print("--[PARTIAL CORRELATION]-------------------------")
print("Anderson-Darling test for features (p-value < 5%):")
pc_normal_features, pc_non_normal_features = anderson_darling_test(pc_upper_tris)
print(f"  - Number of normal features: {len(pc_normal_features)}")
print(f"  - Number of non-normal features: {len(pc_non_normal_features)}")

# pc_normal_features contains the indexes of the features with normal distribution in pc_upper_tris array
pc_p_values = t_test_select_features(all_subjects, pc_upper_tris)
pc_feature_extraction = generate_feature_matrix_result(pc_p_values, pc_normal_features, experiment_feature_count)

# filter the lines from fc_feature_extraction where p_value < 0.05 and is_normal is 1.0
pc_feature_extraction_selected = pc_feature_extraction[
    (pc_feature_extraction["p_value"].astype(float) < 0.05) & (pc_feature_extraction["is_normal"].astype(float) == 1.0)
]
pc_feature_extraction_selected = pc_feature_extraction_selected.sort_values(by="p_value")
pc_feature_extraction_selected.drop(columns=["is_normal"], inplace=True)

print("Selected features (p-value < 0.05 and is_normal = True):")

with pd.option_context("display.max_rows", None, "display.max_columns", None):  # more options can be specified also
    print(pc_feature_extraction_selected.to_string(index=False))

# get all distinct values for feature_x and feature_y in a single array
distinct_features = np.unique(
    np.concatenate(
        (pc_feature_extraction_selected["feature_x"].to_numpy(), pc_feature_extraction_selected["feature_y"].to_numpy())
    )
)

print("Distinct features (x/y): ")
print(distinct_features)

print(fc_feature_extraction_selected)

fc_subject_feature_df = create_subject_feature_df(fc_feature_extraction_selected, fc_upper_tris, all_subjects, experiment_feature_count)
pc_subject_feature_df = create_subject_feature_df(pc_feature_extraction_selected, pc_upper_tris, all_subjects, experiment_feature_count)
fcpc_subject_feature_df = create_subject_feature_combined_df(fc_feature_extraction_selected, pc_feature_extraction_selected, fc_upper_tris, pc_upper_tris, all_subjects, experiment_feature_count)

# write csv files to be used as training data
# the order of the columns are from left to right the smaller p-values to the bigger p-values
fc_subject_feature_df.to_csv(f"{target_dir}/fc_training_data.csv", index=False)
pc_subject_feature_df.to_csv(f"{target_dir}/pc_training_data.csv", index=False)
fcpc_subject_feature_df.to_csv(f"{target_dir}/fcpc_training_data.csv", index=False)
