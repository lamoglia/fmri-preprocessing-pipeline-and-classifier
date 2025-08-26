# This script reads the files with preprocessed timeseries for each subject
# and outputs a csv file containing the selected features and its values for each subject to be
# used as training data for the machine learning model.
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from scipy.stats import anderson
from scipy.stats import ttest_ind
import pingouin as pg

def get_feature_count(filename):
    dr_subject_data = pd.read_csv(filename, sep=",", header=None)
    df = pd.DataFrame(dr_subject_data)
    return len(df.columns)

def get_full_correlation_matrix(filename):
    dr_subject_data = pd.read_csv(filename, sep=",", header=None)
    df = pd.DataFrame(dr_subject_data)

    full_correlation_matrix = df.corr()
    np_full_correlation_matrix = full_correlation_matrix.to_numpy()
    return np_full_correlation_matrix

def get_partial_correlation_matrix(filename):
    dr_subject_data = pd.read_csv(filename, sep=",", header=None)
    df = pd.DataFrame(dr_subject_data)

    partial_correlation_matrix = df.pcorr()
    np_partial_correlation_matrix = partial_correlation_matrix.to_numpy()
    return np_partial_correlation_matrix


def plot_correlation_matrix(correlation_matrix, title):
    plt.figure(figsize=(8, 6))
    sns.heatmap(correlation_matrix, annot=True, cmap="coolwarm", fmt=".2f", linewidths=0.5)
    plt.title(title)
    plt.show()


def plot_correlation_matrix_to_file(correlation_matrix, title, filename):
    plt.figure(figsize=(20, 12))
    sns.heatmap(correlation_matrix, annot=True, cmap="coolwarm", fmt=".2f", linewidths=0.5, cbar=False)
    plt.title(title)
    plt.savefig(filename, bbox_inches="tight", format="jpg")
    plt.close()


def get_upper_tri(matrix):
    return matrix[np.triu_indices_from(matrix, k=1)]


# convert a index on the upper tri array to x, y coordinates on the correlation matrix
def get_coordinates_on_correlation_matrix_from_upper_tri_array_index(upper_tri_index, matrix_size):
    x = 0
    y = 0
    for i in range(matrix_size):
        for j in range(matrix_size):
            if i < j:
                if upper_tri_index == 0:
                    x = i
                    y = j
                    return x, y
                upper_tri_index -= 1
    return x, y


def get_upper_tri_array_index_from_coordinates(x, y, matrix_size):
    upper_tri_index = 0
    for i in range(matrix_size):
        for j in range(matrix_size):
            if i < j:
                if i == x and j == y:
                    return upper_tri_index
                upper_tri_index += 1
    return -1


def anderson_darling_test(data):
    n_features = data.shape[1]
    ad_results = []

    for i in range(n_features):
        feature_values = data[:, i]
        result = anderson(feature_values, dist="norm")  # Test for normality
        ad_results.append((result.statistic, result.critical_values, result.significance_level))

    normal_features = []
    non_normal_features = []

    # Step 3: Interpret the Anderson-Darling results
    for i, (statistic, critical_values, significance_levels) in enumerate(ad_results):
        if statistic >= critical_values[2]:  # Compare with 5% significance level
            non_normal_features.append(i)
        else:
            normal_features.append(i)

    return normal_features, non_normal_features


# T-test to check whether the mean correlation values of each feature differ significantly between ASD and non-ASD groups.
def t_test_select_features(all_subjects, upper_tris):
    # Assume labels is a binary array where 1 = ASD, 0 = non-ASD
    asd_corr = upper_tris[all_subjects["is_asd"] == 1]
    non_asd_corr = upper_tris[all_subjects["is_asd"] == 0]

    # Perform t-test for each feature (column)
    t_stat, p_value = ttest_ind(asd_corr, non_asd_corr, axis=0)

    return p_value


def generate_feature_matrix_result(pc_p_values, pc_normal_features, matrix_size):
    pc_feature_extraction = np.empty((0, 4))
    pc_feature_extraction = np.append(
        pc_feature_extraction, [["p_value", "is_normal", "feature_x", "feature_y"]], axis=0
    )

    # iterate over pc_p_values, for each index, get x and y coordinates on the correlation matrix
    for i in range(len(pc_p_values)):
        x, y = get_coordinates_on_correlation_matrix_from_upper_tri_array_index(i, matrix_size)
        pc_feature_extraction = np.append(
            pc_feature_extraction, [[pc_p_values[i], i in pc_normal_features, x, y]], axis=0
        )

    df = pd.DataFrame(pc_feature_extraction[1:], columns=pc_feature_extraction[0])

    df["feature_x"] = df["feature_x"].astype(float).astype(int)
    df["feature_y"] = df["feature_y"].astype(float).astype(int)

    return df


def create_subject_feature_combined_df(
    fc_feature_extraction_selected, pc_feature_extraction_selected, fc_correlation_matrix_upper_tris, pc_correlation_matrix_upper_tris, all_subjects, matrix_size):
    # Create the input files with the selected features
    # Save the dataframe as a csv file

    fc_feature_extraction_selected["correlation_type"] = "fc"
    pc_feature_extraction_selected["correlation_type"] = "pc"

    pcfc_feature_extraction_selected = pd.concat([fc_feature_extraction_selected, pc_feature_extraction_selected])
    pcfc_feature_extraction_selected = pcfc_feature_extraction_selected.sort_values(by="p_value")


    columns = [
        f"{row['correlation_type']}_corr_{row['feature_x']}_{row['feature_y']}"
        for _, row in pcfc_feature_extraction_selected.iterrows()
    ]
    
    # Create the DataFrame in one step to avoid fragmentation
    subject_feature_df = pd.DataFrame(
        data=0.0,
        index=[0],
        columns=columns
    )
    subject_feature_df["sub_id"] = ""
    subject_feature_df["is_asd"] = False

    for index, row in pcfc_feature_extraction_selected.iterrows():
        if(row["correlation_type"] == "fc"):
            for i in range(len(fc_correlation_matrix_upper_tris)):
                index = get_upper_tri_array_index_from_coordinates(row["feature_x"], row["feature_y"], matrix_size)
                feature = f"fc_corr_{row['feature_x']}_{row['feature_y']}"
                feature_value = fc_correlation_matrix_upper_tris[i][index]
                subject_feature_df.loc[i, feature] = feature_value
        else:
            for i in range(len(pc_correlation_matrix_upper_tris)):
                index = get_upper_tri_array_index_from_coordinates(row["feature_x"], row["feature_y"], matrix_size)
                feature = f"pc_corr_{row['feature_x']}_{row['feature_y']}"
                feature_value = pc_correlation_matrix_upper_tris[i][index]
                subject_feature_df.loc[i, feature] = feature_value

    for i in range(len(fc_correlation_matrix_upper_tris)):
        subject_is_asd = all_subjects.iloc[i]["is_asd"]
        subject_feature_df.loc[i, "sub_id"] = all_subjects.iloc[i]["sub_id"]
        subject_feature_df.loc[i, "is_asd"] = subject_is_asd == 1.0

    return subject_feature_df


def create_subject_feature_df(
    fc_feature_extraction_selected, correlation_matrix_upper_tris, all_subjects, matrix_size):
    # Create the input files with the selected features
    # Save the dataframe as a csv file
    # Collect column names first
    columns = [
        f"corr_{row['feature_x']}_{row['feature_y']}"
        for _, row in fc_feature_extraction_selected.iterrows()
    ]
    
    # Create the DataFrame in one step to avoid fragmentation
    subject_feature_df = pd.DataFrame(
        data=0.0,
        index=[0],
        columns=columns
    )
    subject_feature_df["sub_id"] = ""
    subject_feature_df["is_asd"] = False

    # Iterate over fc_feature_extraction_selected and print each pair (feature_x, feature_y) and the p_value
    for index, row in fc_feature_extraction_selected.iterrows():
        for i in range(len(correlation_matrix_upper_tris)):
            index = get_upper_tri_array_index_from_coordinates(row["feature_x"], row["feature_y"], matrix_size)
            feature = f"corr_{row['feature_x']}_{row['feature_y']}"
            feature_value = correlation_matrix_upper_tris[i][index]
            subject_feature_df.loc[i, feature] = feature_value

    for i in range(len(correlation_matrix_upper_tris)):
        subject_is_asd = all_subjects.iloc[i]["is_asd"]
        subject_feature_df.loc[i, "sub_id"] = all_subjects.iloc[i]["sub_id"]
        subject_feature_df.loc[i, "is_asd"] = subject_is_asd == 1.0

    return subject_feature_df
