#!/bin/bash

iso=$1
isoinfo=$(isoinfo -d -i "$1" 2>/dev/null)
UMD_DATA=$(isoinfo -i "$iso" -x /UMD_DATA.BIN 2>/dev/null | strings | cut -d'|' -f1)
UMD_VIDEO=$(isoinfo -i "$iso" -x /UMD_VIDEO/PARAM.SFO 2>/dev/null | strings | tail -n 1)
UMD_AUDIO=$(isoinfo -i "$iso" -x /UMD_AUDIO/PARAM.SFO 2>/dev/null | strings | tail -n 1)
filename=$(basename "$iso")

# The longest title is probably the right one
TITLE="$UMD_DATA"
if [ ${#UMD_VIDEO} -gt ${#TITLE} ]; then TITLE="$UMD_VIDEO"; fi
if [ ${#UMD_AUDIO} -gt ${#TITLE} ]; then TITLE="$UMD_AUDIO"; fi

AUDIO_TRACKS=$(./umd2mkv -iso "$iso" -inspect | grep Audio | cut -d':' -f2 )
Langs=$(echo $AUDIO_TRACKS | tr '=' ' ' | cut -d' ' -f2,5 | tr ' ' ',' | sed 's/.*/(&)/') 

CRC32=$(crc32 "$iso") 

echo ""
echo "Filename.......: $filename"
echo "Suggested......: $(echo "$TITLE" | tr ' ' '_' | tr -d '[:punct:]') $Langs[$CRC32].iso"
echo "UMD_DATA Title.: $(isoinfo -i "$iso" -x /UMD_DATA.BIN | strings | cut -d'|' -f1)"
if [ -n "$UMD_VIDEO" ]; then
    echo "UMD_VIDEO Title: $(isoinfo -i "$iso" -x /UMD_VIDEO/PARAM.SFO | strings | tail -n 1)"
fi
if [ -n "$UMD_AUDIO" ]; then
    echo "UMD_AUDIO Title: $(isoinfo -i "$iso" -x /UMD_AUDIO/PARAM.SFO | strings | tail -n 1)"
fi

echo "Audio Tracks...:" $AUDIO_TRACKS
echo "Subtitles......:" $(./umd2mkv -iso "$iso" -inspect | grep Subtitle | cut -d':' -f2 | paste -sd, -) 
echo "CRC32..........:" $CRC32 
echo "MD5............:" $(md5sum "$iso" | awk '{ print $1 }') 
echo "SHA1...........:" $(sha1sum "$iso" | awk '{ print $1 }') 
echo "Size...........:" $(wc -c < "$iso") 
echo ""
