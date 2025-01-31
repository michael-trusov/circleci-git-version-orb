#!/bin/bash
#shellcheck disable=all

mkdir -p $INPUT_PARAM_OUTPUT_FOLDER

if [[ $? -eq 0 ]]; then
    echo "Folder '${INPUT_PARAM_OUTPUT_FOLDER}' was created successfully."
else
    echo "Failed to create folder '${INPUT_PARAM_OUTPUT_FOLDER}'."
    return 1
fi
