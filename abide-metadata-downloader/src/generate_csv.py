import os
import pandas as pd
import jq as jq

downloaded_dir="data/out/downloaded"
abide_i_dir=f"{downloaded_dir}/abide-I"
abide_ii_dir=f"{downloaded_dir}/abide-II"

t1w_filename="T1w.json"
task_rest_bold_filename="task-rest_bold.json"
dataset_description_filename="dataset_description.json"
participants_filename="participants.tsv"

all_task_rest_df = pd.DataFrame()

#loop trough each dir in abide_i_dir
for dir in os.listdir(abide_i_dir):
    if dir == "sidecards":
        continue
    # check if task_rest_bold_filename exists inside dir
    if not os.path.exists(f"{abide_i_dir}/{dir}/{task_rest_bold_filename}"):
        print(f"{abide_i_dir}/{dir}/{task_rest_bold_filename} not found")
        task_rest_json = pd.Series()
    else: 
        task_rest_json = pd.read_json(f"{abide_i_dir}/{dir}/{task_rest_bold_filename}", typ='series')
    
    if not os.path.exists(f"{abide_i_dir}/{dir}/{participants_filename}"):
        print(f"{abide_i_dir}/{dir}/{participants_filename} not found")
        total_participants = None
        asd_participants = None
        control_participants = None
    else:
        #read the participants.tsv file as a TSV file with the first row as header to a dataframe
        participants_df = pd.read_csv(f"{abide_i_dir}/{dir}/{participants_filename}", sep="\t")
        total_participants = participants_df.shape[0]
        asd_participants = participants_df[participants_df["DX_GROUP"] == 1].shape[0]
        control_participants = participants_df[participants_df["DX_GROUP"] == 2].shape[0]

    task_rest_json["Version"] = "ABIDE I"
    task_rest_json["Site"] = dir
    task_rest_json["Participants"] = total_participants
    task_rest_json["ASD"] = asd_participants
    task_rest_json["CONTROL"] = control_participants
    task_rest_df = task_rest_json.to_frame().T
    
    # set possible null values
    task_rest_df["RepetitionTime"] = task_rest_df.get("RepetitionTime", "")
    task_rest_df["NumberofMeasurements"] = task_rest_df.get("NumberofMeasurements", "")
    task_rest_df["AcquisitionMatrix"] = task_rest_df.get("AcquisitionMatrix", "")
    task_rest_df["NumberOfSlices"] = task_rest_df.get("NumberOfSlices", "")
    task_rest_df["PlaneOrientationSequentialuence"] = task_rest_df.get("PlaneOrientationSequentialuence", "")
    task_rest_df["SliceAcquisitionOrder"] = task_rest_df.get("SliceAcquisitionOrder", "")
    task_rest_df["PhaseEncodingDirection"] = task_rest_df.get("PhaseEncodingDirection", "")
    task_rest_df["SliceEncodingDirection"] = task_rest_df.get("SliceEncodingDirection", "")
    task_rest_df["SliceTiming"] = task_rest_df.get("SliceTiming", "")

    task_rest_df = task_rest_df[['Version', 'Site', 'Participants', 'ASD', 'CONTROL', 'RepetitionTime', 'NumberofMeasurements', 'AcquisitionMatrix', 'NumberOfSlices', 'PlaneOrientationSequentialuence', 'SliceAcquisitionOrder', 'PhaseEncodingDirection', 'SliceEncodingDirection', 'SliceTiming']]
    all_task_rest_df = pd.concat([all_task_rest_df, task_rest_df])


#loop trough each dir in abide_ii_dir
for dir in os.listdir(abide_ii_dir):
    # check if task_rest_bold_filename exists inside dir
    if not os.path.exists(f"{abide_ii_dir}/{dir}/{task_rest_bold_filename}"):
        print(f"{abide_ii_dir}/{dir}/{task_rest_bold_filename} not found")
        task_rest_json = pd.Series()
    else: 
        task_rest_json = pd.read_json(f"{abide_ii_dir}/{dir}/{task_rest_bold_filename}", typ='series')

    if not os.path.exists(f"{abide_ii_dir}/{dir}/{participants_filename}"):
        print(f"{abide_ii_dir}/{dir}/{participants_filename} not found")
        total_participants = None
        asd_participants = None
        control_participants = None
    else:
        #read the participants.tsv file as a TSV file with the first row as header to a dataframe
        participants_df = pd.read_csv(f"{abide_ii_dir}/{dir}/{participants_filename}", sep="\t", encoding='Latin-1')
        total_participants = participants_df.shape[0]
        asd_participants = participants_df[participants_df["dx_group"] == 1].shape[0]
        control_participants = participants_df[participants_df["dx_group"] == 2].shape[0]

    task_rest_json["Version"] = "ABIDE II"
    task_rest_json["Site"] = dir
    task_rest_json["Participants"] = total_participants
    task_rest_json["ASD"] = asd_participants
    task_rest_json["CONTROL"] = control_participants
    task_rest_df = task_rest_json.to_frame().T
    
    # set possible null values
    task_rest_df["RepetitionTime"] = task_rest_df.get("RepetitionTime", "")
    task_rest_df["NumberofMeasurements"] = task_rest_df.get("NumberofMeasurements", "")
    task_rest_df["AcquisitionMatrix"] = task_rest_df.get("AcquisitionMatrix", "")
    task_rest_df["NumberOfSlices"] = task_rest_df.get("NumberOfSlices", "")
    task_rest_df["PlaneOrientationSequentialuence"] = task_rest_df.get("PlaneOrientationSequentialuence", "")
    task_rest_df["SliceAcquisitionOrder"] = task_rest_df.get("SliceAcquisitionOrder", "")
    task_rest_df["PhaseEncodingDirection"] = task_rest_df.get("PhaseEncodingDirection", "")
    task_rest_df["SliceEncodingDirection"] = task_rest_df.get("SliceEncodingDirection", "")
    task_rest_df["SliceTiming"] = task_rest_df.get("SliceTiming", "")

    task_rest_df = task_rest_df[['Version', 'Site', 'Participants', 'ASD', 'CONTROL', 'RepetitionTime', 'NumberofMeasurements', 'AcquisitionMatrix', 'NumberOfSlices', 'PlaneOrientationSequentialuence', 'SliceAcquisitionOrder', 'PhaseEncodingDirection', 'SliceEncodingDirection', 'SliceTiming']]
    all_task_rest_df = pd.concat([all_task_rest_df, task_rest_df])
        
all_task_rest_df = all_task_rest_df.reset_index(drop=True)

all_task_rest_df = all_task_rest_df[['Version', 'Site'] + [col for col in all_task_rest_df.columns if col not in ['Version', 'Site']]]
all_task_rest_df.to_csv("data/out/fmri_scan_parameters_task_rest.csv", index=False)