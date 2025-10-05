#!/bin/sh
set -e

SCRIPT_DIR=$(dirname $0)
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} file found, loading environment variables ✅"
  set -a
  source "${ENV_FILE}"
  set +a
else
  echo "${ENV_FILE} file does not exist, exiting... ❌"
  exit 1
fi

echo "Creating Connectors in Kafka Connect"

# Directory to search (default is current folder if not provided)
DIR="${1:-.}"

ls $DIR

# Check if directory exists
if [ ! -d "${DIR}" ]; then
  echo "Directory '$DIR' does not exist ❌"
  exit 1
fi

# Find all .json files and loop over them
for file in "${DIR}"/*.json; do
  # Handle case when no .json files exist
  if [ "$file" = "$DIR/*.json" ]; then
    echo "No .json files found in $DIR"
    break
  fi

  echo "Found JSON file: ${file}"

  json_data=$(cat "$file" | sed 's/\"/\\"/g')
  eval_json_data=$(eval "echo \"$json_data\"")
  echo "$eval_json_data"

  final_filename=$(echo "final_"$(basename "${file}"))
  echo $eval_json_data > "${final_filename}"

  curl \
    -H 'Content-Type: application/json' \
    -X POST \
    -d @"$final_filename" \
    http://kafka-connect:8083/connectors

  rm "$final_filename"

done
