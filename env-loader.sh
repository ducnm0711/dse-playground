#!/bin/bash

# Folder containing the key-value text files
FOLDER="secret"
TEMPLATE_FOLDER="templates"

# Output file
OUTPUT_FILE="result"

# Create an associative array to store key-value pairs
declare -A key_value_pairs

# Function to read key-value files and populate the associative array
read_key_value_files() {
  for file in "$FOLDER"/*; do
    key=$(basename "$file")
    value=$(cat "$file")
    key_value_pairs["$key"]="$value"
  done
}

# Function to replace placeholders in the template with values from the associative array
replace_placeholders_in_template() {
  local template_content="$1"
  local new_template="$template_content"

  for key in "${!key_value_pairs[@]}"; do
    value=${key_value_pairs["$key"]}
    new_template=$(echo "$new_template" | sed "s/\$$key/$value/g")
  done

  echo "$new_template"
}

# Create arrays with all files in the folders
template_files=("$TEMPLATE_FOLDER"/*)

# Read key-value files and populate the associative array
read_key_value_files

# Ensure the key-value folder is not empty
if [ ${#key_value_pairs[@]} -eq 0 ]; then
  echo "No key-value files found in $FOLDER"
  exit 1
fi

# Ensure the template folder is not empty
if [ ${#template_files[@]} -eq 0 ]; then
  echo "No template files found in $TEMPLATE_FOLDER"
  exit 1
fi

# Clear the output file if it exists
> "$OUTPUT_FILE"

# Process each template file in the array
for template_file in "${template_files[@]}"; do
  echo "Processing template file: $template_file"

  template_content=$(cat "$template_file")
  result=$(replace_placeholders_in_template "$template_content")

  echo "Result for template $template_file:"
  echo "$result"

  # Append the result to the output file
  echo "$result" >> "$OUTPUT_FILE"
done

echo "Results have been written to $OUTPUT_FILE"