#!/bin/bash
shopt -s nullglob

# Validate input argument
DIR="${1:-.}"
if [[ ! -d "$DIR" ]]; then
    echo "Error: '$DIR' is not a valid directory."
    exit 1
fi

rm umdsurvey.txt 2>/dev/null
rm umdindex.tsv 2>/dev/null

# Find all iso files recursively
# Using -print0 separates filenames with a null byte
find "$DIR" -type f -iname "*.iso" -print0 | while IFS= read -r -d '' iso; do

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

#CRC32=$(crc32 "$iso" |cut -f1) 

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
SERIAL=""
ASCITITLE="${TITLESAFE//[^[:ascii:]]/}"
if [[ "$ASCITITLE" != "$TITLESAFE" ]]; then
    SERIAL="[$UMD_DATA] "
fi

suggested_name="${TITLESAFE} $Langs $SERIAL[$CRC32].iso"

echo "$suggested_name"
echo "$suggested_name" >> umdsurvey.txt
printf "$suggested_name\t$filepath/$filename" >> umdindex.tsv

sort -u umdsurvey.txt -o umdsurvey.txt
sort -u umdindex.tsv -o umdindex.tsv

done
