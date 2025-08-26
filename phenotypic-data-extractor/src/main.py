import os
import pandas as pd

participant_list = []

for root, dirs, files in os.walk("./data"):
    for file in files:
        if file == "participants.tsv":
            participant_list.append(os.path.join(root, file))


#create a df to concatenate all data into
all_df = pd.DataFrame()

#iterate over each element in list
for participant_file in participant_list:
    #read the tab separated csv file, first row is header
    c = participant_file.split("/")
    abide_version=c[4].upper()
    site=c[5]

    #if site contains abide_version + _, remove it
    if site.startswith('ABIDEII-'):
        site = site[len('ABIDEII-'):]

    participant_df = pd.DataFrame()

    if(abide_version == "ABIDE1"):
        participant_df = pd.read_csv(participant_file, sep="\t", header=0, encoding='latin')
        participant_df = participant_df[participant_df.columns.intersection(['participant_id', 'SEX', 'AGE_AT_SCAN', 'DX_GROUP', 'FIQ'])]
        participant_df = participant_df.rename(columns={"SEX": "sex"})
        participant_df = participant_df.rename(columns={"AGE_AT_SCAN": "age"})
        participant_df = participant_df.rename(columns={"DX_GROUP": "group"})
        participant_df = participant_df.rename(columns={"FIQ": "full_iq"})

    if(abide_version == "ABIDE2"):
        participant_df = pd.read_csv(participant_file, sep="\t", header=0, encoding='latin')
        participant_df = participant_df[participant_df.columns.intersection(['participant_id', 'sex', 'age_at_scan ', 'dx_group', 'fiq'])]
        participant_df = participant_df.rename(columns={"sex": "sex"})
        participant_df = participant_df.rename(columns={"age_at_scan ": "age"})
        participant_df = participant_df.rename(columns={"dx_group": "group"})
        participant_df = participant_df.rename(columns={"fiq": "full_iq"})

    #rename participant_id to sub_id
    participant_df = participant_df.rename(columns={"participant_id": "sub_id"})

    #change the values of column group. if 1, set "ASD", if 2 set "CONTROL"
    participant_df["group"] = participant_df["group"].apply(lambda x: "ASD" if x == 1 else "CONTROL")

    participant_df["abide_version"] = abide_version
    participant_df["site"] = site

    #make abide_version and site the first columns
    cols = participant_df.columns.tolist()
    cols = cols[-2:] + cols[:-2]
    participant_df = participant_df[cols]

    #concatenate to all_df
    all_df = pd.concat([all_df, participant_df])


#if full_iq is -9999.0, set to null
all_df["full_iq"] = all_df["full_iq"].apply(lambda x: None if x == -9999.0 else x)

#if sex is 1, set to "M", if 2 set to "F"
all_df["sex"] = all_df["sex"].apply(lambda x: "M" if x == 1 else "F")

#write to out.csv
all_df.to_csv("./data/out/abide_participants_phenotype.csv", index=False)