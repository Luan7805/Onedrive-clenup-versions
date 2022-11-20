#!/bin/bash

REMOTE="onedrive"
VERSIONS_TO_KEEP=3

command -v curl >/dev/null 2>&1 || { echo >&2 "curl is not installed. Aborting..."; exit 1; } # apt install curl
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. Aborting..."; exit 1; } # apt install jq
command -v rclone >/dev/null 2>&1 || { echo >&2 "rclone is not installed. Aborting..."; exit 1; } # curl https://rclone.org/install.sh | bash

DRIVE_ID="$(rclone config dump | jq -r --arg remote "$REMOTE" '.[$remote].drive_id')"

# Find folder ID
function get_folder_id {
  FOLDER_LOCATION="$1"
  rclone about "${REMOTE}:" >/dev/null 2>&1
  ACCESS_TOKEN="$(rclone config dump | jq -r --arg remote "$REMOTE" '.[$remote].token | fromjson | .access_token')"

  echo -e "Searching ${FOLDER_LOCATION} folder id..."
  curl -s \
    -X 'GET' \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H 'Accept: application/json' \
    "https://graph.microsoft.com/v1.0/drives/${DRIVE_ID}/root:/${FOLDER_LOCATION}" |
    jq -r '.id' |
    tr -d '"' |
    while read -r ID; do
      list_dir "$FOLDER_LOCATION" "https://graph.microsoft.com/v1.0/drives/${DRIVE_ID}/items/${ID}/children"
    done
}

# List files in a folder and subfolders
function list_dir {
  rclone about "${REMOTE}:" >/dev/null 2>&1
  ACCESS_TOKEN="$(rclone config dump | jq -r --arg remote "$REMOTE" '.[$remote].token | fromjson | .access_token')"

  FOLDER_NAME="$1"
  URL="$2"

  echo -e "Listing directory: ${FOLDER_NAME}"

  RESPONSE=$(curl -s \
    -X 'GET' \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H 'Accept: application/json' \
    "${URL}")

  echo "$RESPONSE" |
    jq -r '.value[] | "\(if (.file != null) then "file" else "directory" end) \(.id) \(.name)"' |
    while read -r TYPE ID NAME; do
      if [[ "$TYPE" == "file" ]]; then
        get_versions "$ID" "$NAME"
      else
        list_dir "$FOLDER_NAME/$NAME" "https://graph.microsoft.com/v1.0/drives/${DRIVE_ID}/items/${ID}/children"
      fi
    done

  NEXT_URL=$(echo "$RESPONSE" | jq -r '.["@odata.nextLink"]')
  if [[ "$NEXT_URL" != "null" ]]; then
    list_dir "$FOLDER_NAME" "$NEXT_URL"
  fi
}

# Find all versions of a file and delete whichever is greater than the number of versions to keep
function get_versions {
  ITEM_ID="$1"
  FILE_NAME="$2"

  echo "Checking versions for: ${FILE_NAME}"
  curl -s \
    -X 'GET' \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H 'Accept: application/json' \
    "https://graph.microsoft.com/v1.0/drives/${DRIVE_ID}/items/${ITEM_ID}/versions" |
    jq -r '.value[].id' |
    tail -n+$((VERSIONS_TO_KEEP + 1)) |
    while read -r VERSION_ID; do
      echo "Deleting version: ${VERSION_ID}"
      curl -s \
        -X 'DELETE' \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H 'Accept: application/json' \
        "https://graph.microsoft.com/v1.0/drives/${DRIVE_ID}/items/${ITEM_ID}/versions/${VERSION_ID}"
    done
}

get_folder_id "$1"
