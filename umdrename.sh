#!/bin/bash
shopt -s nullglob

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

# Get or calc CRC32 checksum of the ISO file
if [[ $iso =~ [\[\(]([a-fA-F0-9]{8})[\]\)]\.[iI][sS][oO]$ ]]; then
        CRC32="${BASH_REMATCH[1]}"
    else
        CRC32=$(crc32 "$iso" | cut -f1)
fi
CRC32=$(echo "$CRC32" | tr '[:lower:]' '[:upper:]')

# For non-ascii titles, add the serial number to the filename
ASCITITLE="${TITLESAFE//[^[:ascii:]]/}"
if [[ "$ASCITITLE" != "$TITLESAFE" ]]; then
    SERIAL="[$UMD_DATA] "
fi

suggested_name="${TITLESAFE} $Langs $SERIAL[$CRC32].iso"

# Double rename if case insensitive file system has a conflict with the new name
if [ -f "$filepath/$suggested_name" ]; then
    mv "$iso" "$filepath/_$suggested_name"
    # Check again for duplicate after first rename
    if [ -f "$filepath/$suggested_name" ]; then
        mkdir -p "$filepath/duplicates"
        echo "Duplicate found, moving $filename to duplicates folder"
        mv "$filepath/_$suggested_name" "$filepath/duplicates/$filename"
    else
        echo "Renaming $filename to $suggested_name"
        mv "$filepath/_$suggested_name" "$filepath/$suggested_name"
    fi
    exit 1
fi
#echo "old name..: $filename"
#echo "new name..: $suggested_name"
echo "Renaming..: $filepath/$suggested_name"
mv "$iso" "$filepath/$suggested_name"
