#!/bin/sh
# Generates a csv file using extract.py to extract tr and voxel size

PYTHON_FILE="./extract.py"

# Directory containing the raw NIfTI files from ABIDE
RAW_FILES_BASE_PATH="/mnt/e/data/input/ABIDE1/raw/BIDS"

echo "file;tr;pixel_size;volumes;image_size"
find $RAW_FILES_BASE_PATH -wholename /*/func/*.nii.gz | while IFS=$'\n' read line; do
    tr=`python3 $PYTHON_FILE $line --tr`
    pixel=`python3 $PYTHON_FILE $line --pixel`
    length=`python3 $PYTHON_FILE $line --length`
    size=`python3 $PYTHON_FILE $line --size`
    echo "$line;$tr;$pixel;$length;$size"
done