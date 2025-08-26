#!/bin/zsh
# This script downloads metadata from ABIDE repository using duck

# download abide I

BASE_DIR="./data/out/downloaded"
ABIDE_I_DIR="${BASE_DIR}/abide-I"
ABIDE_II_DIR="${BASE_DIR}/abide-II"

mkdir -p "${ABIDE_I_DIR}"
mkdir -p "${ABIDE_II_DIR}"

declare -a abide_I_sites=("CMU_b" "Caltech" "KKI" "Leuven_1" "Leuven_2" "MaxMun_a" "MaxMun_b" "MaxMun_c" "MaxMun_d" "NYU" "OHSU" "Olin" "Pitt" "SBL" "SDSU" "Stanford" "Trinity" "UCLA_1" "UCLA_2" "UM_1" "UM_2" "USM" "Yale")

declare -a files=("T1w.json" "dataset_description.json" "dwi.json" "participants.tsv" "task-rest_bold.json")

echo "Downloading ABIDE I metadata"

for site in "${abide_I_sites[@]}"
do
    mkdir -p ${ABIDE_I_DIR}/${site}
    for file in "${files[@]}"
    do
        echo "Downloading ${site} - ${file}..."
        duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE/RawDataBIDS/${site}/${file} ${ABIDE_I_DIR}/${site}
    done
done

echo ""
echo "Downloading ABIDE II metadata"

# declare abide_II_sites 

declare -a abide_II_sites=("ABIDEII-BNI_1" "ABIDEII-EMC_1" "ABIDEII-ETHZ_1" "ABIDEII-GU_1" "ABIDEII-IP_1" "ABIDEII-IU_1" "ABIDEII-KKI_1" "ABIDEII-KUL_3" "ABIDEII-NYU_1" "ABIDEII-NYU_2" "ABIDEII-OHSU_1" "ABIDEII-ONRC_2" "ABIDEII-SDSU_1" "ABIDEII-TCD_1" "ABIDEII-UCD_1" "ABIDEII-UCLA_1" "ABIDEII-UCLA_Long" "ABIDEII-UPSM_Long" "ABIDEII-USM_1")

for site in "${abide_II_sites[@]}"
do
    mkdir -p ${ABIDE_II_DIR}/${site}
    for file in "${files[@]}"
    do
        echo "Downloading ${site} - ${file}..."
        duck --anonymous -d s3:fcp-indi/data/Projects/ABIDE2/RawData/${site}/${file} ${ABIDE_II_DIR}/${site}
    done
done
