#!/bin/bash

iso=$1

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

# For non-ascii titles, add the serial number to the filename
ASCITITLE="${TITLESAFE//[^[:ascii:]]/}"
if [[ "$ASCITITLE" != "$TITLESAFE" ]]; then
    SERIAL=" [$UMD_DATA] "
fi

suggested_name="${TITLESAFE} $Langs$SERIAL[$CRC32].iso"

echo ""
echo "File Name......: $filename"
echo "Suggested Name.: $suggested_name"
echo "UMD_DATA Title.: $UMD_DATA"
echo "UMD_VIDEO Title: $UMD_VIDEO"
echo "UMD_AUDIO Title: $UMD_AUDIO"
echo "Audio Tracks...:" $AUDIO_TRACKS
echo "Subtitles......:" $(umd2mkv -iso "$iso" -inspect | grep Subtitle | cut -d':' -f2 | paste -sd, -) 
echo "CRC32..........:" $CRC32 
echo "MD5............:" $(md5sum "$iso" | awk '{ print $1 }') 
echo "SHA1...........:" $(sha1sum "$iso" | awk '{ print $1 }') 
echo "Size in bytes..:" $(wc -c < "$iso") 
echo ""
