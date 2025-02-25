#!/bin/bash
#shellcheck disable=all

debug_message() {
    local message=$1

    if [[ "${INPUT_PARAM_DEBUG}" == "true" ]]; then
        echo "[DEBUG] $message"
    fi
}

current_version_meta_data=$(az acr manifest list-metadata --username $ACR_USERNAME --password $ACR_PASSWORD --registry $REGISTRY --name $REPOSITORY --top 1 --orderby time_desc)
current_latest_tag=$(echo "$current_version_meta_data" | jq -r '.[0].tags[0]')
debug_message "current_latest_tag: $current_latest_tag"

# Note: save to file
echo "$current_latest_tag" > "${INPUT_PARAM_INPUT_FOLDER}/${INPUT_PARAM_INPUT_FILE}"
