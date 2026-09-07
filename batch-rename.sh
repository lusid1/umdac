#!/bin/bash

# Validate input argument
DIR="${1:-.}"
if [[ ! -d "$DIR" ]]; then
    echo "Error: '$DIR' is not a valid directory."
    exit 1
fi

# Find all iso files recursively
# Using -print0 separates filenames with a null byte
find "$DIR" -type f -iname "*.iso" -print0 | while IFS= read -r -d '' file; do
    # Call the umdrename2.sh script for each file
    ./umdrename.sh "$file" "$2"
done
