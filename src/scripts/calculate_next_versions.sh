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

### Description
###   This function compares two versions (strings) in the following format: x.x.x, i.e. 1.2.0 and 11.23.1
###
### Parameters:
###   $1 - version1, i.e. 1.2.0
###   $2 - version2, i.e. 11.23.1
###
### Returns:
###   returns 0 if 'version1' <= 'version2'
###   returns 1 if 'version1' > 'version2'
compare_versions() {
    local version1=$1
    local version2=$2    

    IFS='.' read -ra v1_parts <<< "$version1"
    IFS='.' read -ra v2_parts <<< "$version2"

    result=0
    for i in {0..2}; do
        if (( ${v1_parts[$i]} < ${v2_parts[$i]} )); then
            break
        elif (( ${v1_parts[$i]} > ${v2_parts[$i]} )); then
            result=1
            break
        fi
    done

    echo "$result"
}

### Description
###   This function filters collection of strings (tags), result includes only tags with the highest version,
###   for example, 
###     input tags: v1.11.0 v1.11.0-alpha.1 v1.11.0-alpha.2 v1.11.0-beta.1 v1.10.0 v1.10.1-alpha.1
###     result:     v1.11.0 v1.11.0-alpha.1 v1.11.0-alpha.2 v1.11.0-beta.1
###   note: 1.11.0*** is the highest versions from the input collection
###
### Parameters:
###   $1 - reference to array of strings (tags)
###
### Returns:
###   array of strings (tags)
filter_the_highest_versions() {
    local -n arg_tags=$1

    filtered_tags=()

    highest_version=""
    for tag in "${arg_tags[@]}"; do
        currentTag=$(echo "$tag" | grep -oP '^v(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta|rc)\.(\d+))?$')
        if [ -n "$currentTag" ]; then
            version=""
            if [[ $currentTag == *"-alpha."* ]]; then
                [[ $currentTag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)-alpha\.([0-9]+)$ ]]
                version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            elif [[ $currentTag == *"-beta."* ]]; then
                [[ $currentTag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)-beta\.([0-9]+)$ ]]
                version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            elif [[ $currentTag == *"-rc."* ]]; then
                [[ $currentTag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)-rc\.([0-9]+)$ ]]
                version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            else
                [[ $currentTag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
                version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
            fi

            if [[ -z "$highest_version" || $(compare_versions "$version" "$highest_version") -eq 1 ]]; then                
                highest_version="$version"
                filtered_tags=("$tag")
            elif [[ "$version" == "$highest_version" ]]; then
                filtered_tags+=("$tag")
            fi
        fi
    done

    echo "${filtered_tags[@]}"
}

### Description
###   This function try to get production version (version without any suffix) from the passed collection,
###   for example, 
###     input tags: v1.11.0 v1.11.0-alpha.1 v1.11.0-alpha.2 v1.11.0-beta.1
###     result:     v1.11.0
###   note: 1.11.0 is production version, it is higher than v1.11.0-alpha.1, v1.11.0-alpha.2 or v1.11.0-beta.1
###
### Parameters:
###   $1 - reference to array of strings (tags)
###
### Returns:
###   string (production version) is returned if found, otherwise empty string is returned
try_to_get_production_version() {
    local -n arg_tags=$1

    production_tag=""
    for tag in "${arg_tags[@]}"; do
        current_tag=$(echo "$tag" | grep -oP '^v(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta|rc)\.(\d+))?$')
        if [[ $current_tag == *"-alpha."* || $current_tag == *"-beta."* || $current_tag == *"-rc."* ]]; then
            continue
        else
            production_tag=$current_tag
            break
        fi
    done
    
    echo "$production_tag"
}

### Description
###   This function calculates next version for passed suffix (alpha, beta or rc) version based on passed collection,
###   for example, 
###     input tags: 'alpha' and v1.11.0 v1.11.0-alpha.1 v1.11.0-alpha.2 v1.11.0-beta.1
###     result:     v1.11.0-alpha.3
###
### Parameters:
###   $1 - suffix (alpha, beta or rc)
###   $2 - reference to array of strings (tags)
###
### Returns:
###   string (next version) is returned
get_next_version() {
    local suffix=$1
    local -n arg_tags=$2    

    if [ ${#arg_tags[@]} -gt 0 ]; then
        # extracting 'Major.Minor.Patch' version from the first tag, this part
        # must be the same for each element in input collection
        first_tag="${arg_tags[0]}"        
        
        version=""
        if [[ $first_tag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)(-(alpha|beta|rc)\.([0-9]+))?$ ]]; then
            version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"            
        fi

        # calculate next version number
        highest_version_number="0"
        for tag in "${arg_tags[@]}"; do
            if [[ $tag =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)-"${suffix}"\.([0-9]+)$ ]]; then            
                number="${BASH_REMATCH[4]}"
                if [ "$number" -gt "$highest_version_number" ]; then
                    highest_version_number="$number"
                fi
            fi
        done
        
        next_version_number=$((highest_version_number + 1))
        next_tag="v${version}-${suffix}.${next_version_number}"
        
        echo "$next_tag"
    else
        echo ""
    fi    
}

### Description
###   This function calculates next versions for alpha, beta or rc and detect production version if exists. Calculation based on passed collection,
###
### Parameters:
###   $1 - reference to associative array
###   $2 - reference to array of strings (tags)
###
### Returns:
###   nothing
calculate_next_versions() {
    local -n ref_versions=$1
    local -n ref_tags=$2

    # initialize associative array with empty values
    ref_versions["PROD"]=""
    ref_versions["ALPHA"]=""
    ref_versions["BETA"]=""
    ref_versions["RC"]=""

    debug_array_state "Input collection" ref_tags

    read -a the_highest_versions <<< "$(filter_the_highest_versions ref_tags)"

    debug_array_state "The highest detected versions" the_highest_versions

    production_tag=$(try_to_get_production_version the_highest_versions)
    if [[ -n $production_tag ]]; then
        debug_message "Production version detected: $production_tag"

        ref_versions["PROD"]=$production_tag    
    else
        next_alpha_version=$(get_next_version "alpha" the_highest_versions)
        ref_versions["ALPHA"]=$next_alpha_version    

        debug_message "Next alpha version: $next_alpha_version"

        next_beta_version=$(get_next_version "beta" the_highest_versions)
        ref_versions["BETA"]=$next_beta_version 

        debug_message "Next beta version: $next_beta_version"

        next_rc_version=$(get_next_version "rc" the_highest_versions)
        ref_versions["RC"]=$next_rc_version        

        debug_message "Next rc version: $next_rc_version"
    fi
}

declare -A calculated_versions

tags=""
if [[ -z $INPUT_PARAM_TAGS ]]; then
    mapfile -t tags < <(tr -s ' ' '\n' < $INPUT_PARAM_INPUT_FILE)
    if [ ${#tags[@]} -eq 0 ]; then
        echo "No tags were found in the input file"        
        exit 1
    fi
else
    tags=($INPUT_PARAM_TAGS)
fi

calculate_next_versions calculated_versions tags

NEXT_VERSION_PROD=${calculated_versions["PROD"]}
debug_message "'NEXT_VERSION_PROD' was set to: $NEXT_VERSION_PROD"
echo "export NEXT_VERSION_PROD=\"${NEXT_VERSION_PROD}\"" >> "$INPUT_PARAM_OUTPUT_FOLDER/$INPUT_PARAM_OUTPUT_FILE"

NEXT_VERSION_RC=${calculated_versions["RC"]}
debug_message "'NEXT_VERSION_RC' was set to: $NEXT_VERSION_RC"
echo "export NEXT_VERSION_RC=\"${NEXT_VERSION_RC}\"" >> "$INPUT_PARAM_OUTPUT_FOLDER/$INPUT_PARAM_OUTPUT_FILE"

NEXT_VERSION_BETA=${calculated_versions["BETA"]}
debug_message "'NEXT_VERSION_BETA' was set to: $NEXT_VERSION_BETA"
echo "export NEXT_VERSION_BETA=\"${NEXT_VERSION_BETA}\"" >> "$INPUT_PARAM_OUTPUT_FOLDER/$INPUT_PARAM_OUTPUT_FILE"

NEXT_VERSION_ALPHA=${calculated_versions["ALPHA"]}
debug_message "'NEXT_VERSION_ALPHA' was set to: $NEXT_VERSION_ALPHA"
echo "export NEXT_VERSION_ALPHA=\"${NEXT_VERSION_ALPHA}\"" >> "$INPUT_PARAM_OUTPUT_FOLDER/$INPUT_PARAM_OUTPUT_FILE"
