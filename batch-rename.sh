#!/bin/bash

DIR="$1"
#DIR="/mnt/h/ISO/VIDEO"  # Replace with your directory path
#REGEX='^\[.*'  # Example: [GAME]_0001.iso
#REGEX='.*\.iso$'  # Example: *.iso
REGEX='.*\.[iI][sS][oO]$' 

for file in "$DIR"/*; do
    if [[ -f "$file" && $(basename "$file") =~ $REGEX ]]; then
        #./umdrename.sh "$file"
        ./umdrename2.sh "$file"
    fi
done
