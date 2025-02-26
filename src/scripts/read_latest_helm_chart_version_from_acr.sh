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

debug_message "[ENV VAR] ACR_USERNAME=$ACR_USERNAME"
debug_message "[ENV VAR] REPOSITORY=$REPOSITORY"
debug_message "[ENV VAR] REGISTRY=$REGISTRY"

# Note: get metadata of the latest Helm chart stored in repository
current_version_meta_data=$(az acr manifest list-metadata --username $ACR_USERNAME --password $ACR_PASSWORD --registry $REGISTRY --name $REPOSITORY --top 1 --orderby time_desc)
# Note: extract the tag version, i.e. 1.0.0-beta.2
current_latest_tag=$(echo "$current_version_meta_data" | jq -r '.[0].tags[0]')

# Note: add 'v' prefix to the tag version, i.e. v1.0.0-beta.2
current_latest_tag="v${current_latest_tag}"
debug_message "current_latest_tag: $current_latest_tag"

# Note: save tag in file
echo "$current_latest_tag" > "${INPUT_PARAM_INPUT_FOLDER}/${INPUT_PARAM_INPUT_FILE}"
