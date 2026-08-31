#!/bin/bash

iso=$1
echo "Processing: $iso"

UMD_DATA=$(isoinfo -i "$iso" -x /UMD_DATA.BIN 2>/dev/null | strings -eS -n 1| cut -d'|' -f1 | sed 's/[[:space:]]*$//')
UMD_VIDEO=$(isoinfo -i "$iso" -x /UMD_VIDEO/PARAM.SFO 2>/dev/null | strings -eS -n 1| tail -n 1 | sed 's/[[:space:]]*$//' )
UMD_AUDIO=$(isoinfo -i "$iso" -x /UMD_AUDIO/PARAM.SFO 2>/dev/null | strings -eS -n 1| tail -n 1 | sed 's/[[:space:]]*$//' )


filename=$(basename "$iso")
filepath=$(dirname "$iso")

# The longest title is probably the right one
TITLE="$UMD_VIDEO"
#if [ ${#UMD_DATA} -gt ${#TITLE} ]; then TITLE="$UMD_DATA"; fi
if [ ${#UMD_AUDIO} -gt ${#TITLE} ]; then TITLE="$UMD_AUDIO"; fi

AUDIO_TRACKS=$(umd2mkv -iso "$iso" -inspect | grep Audio | cut -d':' -f2 )
Langs=$(
    echo "$AUDIO_TRACKS" \
    | sed 's/, /\n/g' \
    | sed 's/.*=\([^(]*\).*/\1/' \
    | sed 's/[[:space:]]//g' \
    | tr '\n' ',' \
    | sed 's/,$//' \
    | sed 's/.*/(&)/'
)

CRC32=$(crc32 "$iso" |cut -f1) 

# Remove unsafe utf-8 filename character 
export LC_ALL=C.UTF-8
TITLESAFE="$(echo "$TITLE" | tr -d '\r' | awk '
BEGIN {
    # Define forbidden filesystem/shell characters as a regex pattern
    forbidden = "[/\\\\?%*:|\"<>!@#$&*`~;]"
}
{
    # Replace forbidden punctuation with a space
    gsub(forbidden, " ")
    
    # Strip any hidden control characters safely
    gsub(/[[:cntrl:]]/, "")
    
    # Collapse multiple spaces into a single space
    gsub(/  */, " ")
    
    # Remove leading spaces
    gsub(/^ */, "")
    
    # Remove trailing spaces
    gsub(/ *$/, "")
    
    print
}')"

suggested_name="${TITLESAFE} $Langs[$CRC32].iso"

if [ -f "$filepath/$suggested_name" ]; then
    echo "File $suggested_name already exists, moving to duplicates folder."
    mkdir -p "$filepath/duplicates"
    mv "$iso" "$filepath/duplicates/$filename"
    exit 1
fi
#echo "old name..: $filename"
#echo "new name..: $suggested_name"
echo "Renaming..: $filepath/$suggested_name"
mv "$iso" "$filepath/$suggested_name"
