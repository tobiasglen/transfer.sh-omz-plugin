#!/usr/bin/env zsh

PLUGIN_NAME="trs"

TRANSFER_HISTORY_FILE=${TRANSFER_HISTORY_FILE:-"$HOME/.transfer_history"}

_trs_print_usage() {
    echo "Usage: trs [--days value] [--downloads value] [--pw/--password value] path"
    echo "Optional arguments:"
    echo "  --days         Number of days"
    echo "  --downloads    Number of downloads"
    echo "  --pw/--password    Password to encrypt text files"
    echo "Required argument:"
    echo "  path           A valid file or directory path"
}

# Function to check if a variable is set and non-empty
_trs_check_variable() {
    local var_name="$1"
    if [[ -z "${(P)var_name}" ]]; then
        echo "Error: $var_name is not set or is empty"
        return 1
    fi
}

trs() {
    # Verify required tools are installed
    for tool in zip curl grep mktemp tr jq awk; do
        command -v $tool >/dev/null 2>&1 || { echo "Error: $tool is not installed."; return 1; }
    done

    # Check required variables
    local required_vars=(TRANSFER_BASE_URL TRANSFER_HTTP_USER TRANSFER_HTTP_PASS)
    for var in "${required_vars[@]}"; do
        _trs_check_variable "$var" || return 1
    done

    # Initialize variables
    local days="" downloads="" password="" path="" upload_headers=()

    # Parse named arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --days)
                if [[ -n $2 && ${2:0:1} != "-" ]]; then
                    days="$2"
                    upload_headers+=(-H "Max-Days: $days")
                    shift
                else
                    echo "Error: --days requires a value"
                    _trs_print_usage
                    return 1
                fi
                ;;
            --dl|--downloads)
                if [[ -n $2 && ${2:0:1} != "-" ]]; then
                    downloads="$2"
                    upload_headers+=(-H "Max-Downloads: $downloads")
                    shift
                else
                    echo "Error: --downloads requires a value"
                    _trs_print_usage
                    return 1
                fi
                ;;
            --pw|--password)
                if [[ -n $2 && ${2:0:1} != "-" ]]; then
                    password="$2"
                    upload_headers+=(-H "X-Encrypt-Password: $password")
                    shift
                else
                    echo "Error: --pw/--password requires a value"
                    _trs_print_usage
                    return 1
                fi
                ;;
            *)
                # If this is the last argument, treat it as the path
                if [[ $# -eq 1 ]]; then
                    path="$1" upload_file="$1"
                else
                    echo "Unknown argument: $1"
                    _trs_print_usage
                    return 1
                fi
                ;;
        esac
        shift
    done

    # Check if path is provided and valid
    if [[ -z $path ]]; then
        echo "Error: A valid path must be provided as the last argument"
        _trs_print_usage
        return 1
    elif [[ ! -e $path ]]; then
        echo "Error: The provided path does not exist: $path"
        return 1
    fi

    if [[ -d $path ]]; then
        local zipfile=$(/usr/bin/mktemp -t trs.XXXXX.zip )
        cd $path:h && /usr/bin/zip -0 -r -q - $path:t > $zipfile
        upload_file=$zipfile
    fi



    response_headers=$(/usr/bin/mktemp -t trs-headers.XXXXX)
    tmpfile=$(/usr/bin/mktemp -t transfe-progress-XXXXX)  # Create a temporary file for the progress bar

    # Uploads the file and returns response headers as value
    curl_output=$(/usr/bin/curl --request PUT --progress-bar --dump-header - --user "${TRANSFER_HTTP_USER}:${TRANSFER_HTTP_PASS}" "${upload_headers[@]}" --upload-file "${upload_file}" "${TRANSFER_BASE_URL}/")

    # We are interested in the x-url-delete header since it has the full viewing URL and the delete token all in one line
    delete_link=$(/usr/bin/grep -i "x-url-delete:" <<< "${curl_output}"  | /usr/bin/awk '{print $2}')
    delete_token=$(echo "${delete_link##*/}" | /usr/bin/tr -cd '[:print:]')
    viewing_link="${delete_link%/*}"

    inline_view="${viewing_link/$TRANSFER_BASE_URL/$TRANSFER_BASE_URL/inline}"
    download_link="${viewing_link/$TRANSFER_BASE_URL/$TRANSFER_BASE_URL/get}"

    printf '{"web_url": "%s", "inline_url": "%s", "download_url": "%s", "delete_token": "%s"}\n' "$viewing_link" "$inline_view" "$download_link" "$delete_token" | /usr/bin/jq .

    if [[ -n $TRANSFER_HISTORY_FILE ]]; then  # Add the viewing link and delete token to the history file
        echo "$(/usr/bin/date '+%Y-%m-%d %H:%M:%S') | $delete_token | $viewing_link" >> $TRANSFER_HISTORY_FILE
    fi

    # Cleanup
    /usr/bin/rm $tmpfile
    /usr/bin/rm $response_headers
    if [[ -f $zipfile ]]; then
        echo "removing zip: $zipfile"
        /usr/bin/rm $zipfile
    fi
}


# Autoload the plugin functions
autoload -Uz trs
