#!/bin/bash
#shellcheck disable=all

# get Git tags and store them in an array
mapfile -t tags < <(git tag -l)

# join array elements into a space-separated string
tags_string="${tags[*]}"

# save to file
echo "$tags_string" > "${INPUT_PARAM_INPUT_FOLDER}/${INPUT_PARAM_INPUT_FILE}"

# Print confirmation
#echo "Tags saved to tags.txt"
#mapfile -t versions < <(tr -s ' ' '\n' < filename.txt)