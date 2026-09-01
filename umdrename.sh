#!/bin/bash
shopt -s nullglob

iso=$1
echo "Checking..: $iso"

UMD_DATA=$(isoinfo -i "$iso" -x /UMD_DATA.BIN 2>/dev/null | strings -eS -n 1| cut -d'|' -f1 | sed 's/[[:space:]]*$//')
UMD_VIDEO=$(isoinfo -i "$iso" -x /UMD_VIDEO/PARAM.SFO 2>/dev/null | strings -eS -n 1| tail -n 1 | sed 's/[[:space:]]*$//' )
UMD_AUDIO=$(isoinfo -i "$iso" -x /UMD_AUDIO/PARAM.SFO 2>/dev/null | strings -eS -n 1| tail -n 1 | sed 's/[[:space:]]*$//' )


filename=$(basename "$iso")
filepath=$(dirname "$iso")

if [[ $2 == "-copy2dir="* ]]; then
    dstpath="${2#-copy2dir=}"
fi
if [[ $2 == "-move2dir="* ]]; then
    dstpath="${2#-move2dir=}"
fi
if [[ -z "$dstpath" ]]; then
    dstpath="$filepath"
fi
mkdir -p "$dstpath"

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

#If everything checks out we are done
if [[ "$iso" == "$dstpath/$suggested_name" ]]; then
    exit 0
fi

# If we are in copy mode, start with the copy
if [[ $2 == "-copy2dir="* ]]; then
    if [ -f "$dstpath/$suggested_name" ]; then 
        echo "Found.....: $dstpath/$suggested_name"
        exit 0; 
    fi

    echo "Copying...: $dstpath/$suggested_name"
    cp "$iso" "$dstpath/$suggested_name"
    iso="$dstpath/$suggested_name"
fi

# If rename is not required we are done
if [[ "$iso" == "$dstpath/$suggested_name" ]]; then
    exit 0
fi

verbiage="Renaming..:"
if [[ $2 == "-move2dir="* ]]; then
    verbiage="Moving....:"
fi

# Double rename if case insensitive file system has a conflict with the new name
if [ -f "$dstpath/$suggested_name" ]; then
    mv "$iso" "$dstpath/_$suggested_name"
    # Check again for duplicate after first rename
    if [ -f "$dstpath/$suggested_name" ]; then
        mkdir -p "$dstpath/duplicates"
        echo "Duplicate.: $dstpath/$suggested_name"
        mv "$dstpath/_$suggested_name" "$dstpath/duplicates/$filename"
    else
        echo "$verbiage $dstpath/$suggested_name"
        mv "$dstpath/_$suggested_name" "$dstpath/$suggested_name"
    fi
    exit 0
else
    echo "$verbiage $dstpath/$suggested_name"
    mv "$iso" "$dstpath/$suggested_name"
fi



