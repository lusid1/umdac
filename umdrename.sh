#!/bin/bash

iso=$1


UMD_DATA=$(isoinfo -i "$iso" -x /UMD_DATA.BIN 2>/dev/null | strings -n 1| cut -d'|' -f1 | sed 's/[[:space:]]*$//')
UMD_VIDEO=$(isoinfo -i "$iso" -x /UMD_VIDEO/PARAM.SFO 2>/dev/null | strings -n 1| tail -n 1 | sed 's/[[:space:]]*$//' )
UMD_AUDIO=$(isoinfo -i "$iso" -x /UMD_AUDIO/PARAM.SFO 2>/dev/null | strings -n 1| tail -n 1 | sed 's/[[:space:]]*$//' )

filename=$(basename "$iso")
filepath=$(dirname "$iso")

# The longest title is probably the right one
TITLE="$UMD_VIDEO"
if [ ${#UMD_DATA} -gt ${#TITLE} ]; then TITLE="$UMD_DATA"; fi
if [ ${#UMD_AUDIO} -gt ${#TITLE} ]; then TITLE="$UMD_AUDIO"; fi

AUDIO_TRACKS=$(umd2mkv -iso "$iso" -inspect | grep Audio | cut -d':' -f2 )
#Langs=$(echo $AUDIO_TRACKS | tr '=' ' ' | cut -d' ' -f2,5 | tr ' ' ',' | sed 's/.*/(&)/') 
Langs=$(
    echo "$AUDIO_TRACKS" \
    | sed 's/, /\n/g' \
    | sed 's/.*=\([^(]*\).*/\1/' \
    | sed 's/[[:space:]]//g' \
    | tr '\n' ',' \
    | sed 's/,$//' \
    | sed 's/.*/(&)/'
)
echo "Processing $iso"
CRC32=$(crc32 "$iso" |cut -f1) 
#suggested_name="$(echo "$TITLE" | sed 's/[^A-Za-z0-9 _-()]//g' | sed 's/[[:space:]]*$//') $Langs[$CRC32].iso"
suggested_name="$(
    echo "$TITLE" \
    | sed 's/[^A-Za-z0-9 _\-\(\)]//g' \
    | sed 's/[[:space:]]*$//'
) $Langs[$CRC32].iso"

if [ -f "$filepath/$suggested_name" ]; then
    echo "File $suggested_name already exists, skipping rename"
    exit 1
fi
echo "renaming $filename to $suggested_name"
mv "$iso" "$filepath/$suggested_name"
