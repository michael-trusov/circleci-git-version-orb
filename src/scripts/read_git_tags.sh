#!/bin/bash
#shellcheck disable=all

### Description
###   This function print message if INPUT_PARAM_DEBUG is set to 'true'
###
### Parameters:
###   $1 - message
debug_message() {
    local message=$1

    if [[ "${INPUT_PARAM_DEBUG}" == "true" ]]; then
        echo "[DEBUG] $message"
    fi
}

### Description
###   This function print mesarray state if INPUT_PARAM_DEBUG is set to 'true'
###
### Parameters:
###   $1 - message
###   $2 - reference to array
debug_array_state() {
    local message=$1
    local -n array=$2

    if [[ "${INPUT_PARAM_DEBUG}" == "true" ]]; then
        echo "[DEBUG] $message: ${array[@]}"
    fi
}

# get Git tags and store them in an array
mapfile -t tags < <(git tag -l)
debug_array_state "Collection of git tags read from the repo" tags

# join array elements into a space-separated string
tags_string="${tags[*]}"

# save to file
echo "$tags_string" > "${INPUT_PARAM_INPUT_FOLDER}/${INPUT_PARAM_INPUT_FILE}"

# Print confirmation
#echo "Tags saved to tags.txt"
#mapfile -t versions < <(tr -s ' ' '\n' < filename.txt)