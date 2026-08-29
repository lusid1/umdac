#!/bin/bash
dumper="lusid1"
method="USB"
rig="PSP 1000 / ARK-5"

iso=$1
txtfile="$(basename "$iso" .iso)"
txtfile="$(basename "$txtfile" .ISO)"
txtfile="$txtfile.txt"
touch "$txtfile"

UMD_DATA=$(isoinfo -i "$iso" -x /UMD_DATA.BIN | strings | cut -d'|' -f1)
UMD_VIDEO=$(isoinfo -i "$iso" -x /UMD_VIDEO/PARAM.SFO | strings | tail -n 1)
UMD_AUDIO=$(isoinfo -i "$iso" -x /UMD_AUDIO/PARAM.SFO | strings | tail -n 1)

# The longest title is probably the right one
TITLE="$UMD_DATA"
if [ ${#UMD_VIDEO} -gt ${#TITLE} ]; then TITLE="$UMD_VIDEO"; fi
if [ ${#UMD_AUDIO} -gt ${#TITLE} ]; then TITLE="$UMD_AUDIO"; fi

echo "~UMD Archive Collective Info Sheet~ " > "$txtfile"
echo "~~ Anything after the : is where your information goes ~~" >>"$txtfile"
echo "Logical Metadata:" >>"$txtfile"
echo "	Release Title: $TITLE" >>"$txtfile"
echo "	Type of UMD from Cover (Video, Music, or Music Video):" >>"$txtfile"
echo "	Dumper (your username): $dumper"  >>"$txtfile"
echo "	Advertised Region:" >>"$txtfile"
echo "	Country/Region of Release:" >>"$txtfile"
echo "	Catalog/Serial Number:" >>"$txtfile"
echo "	Barcode:" >>"$txtfile"
echo "	Distributor:" >>"$txtfile"
echo "	Secondary Company:" >>"$txtfile"
echo "	Advertised Languages (English, French, etc.):" $(./umd2mkv -iso "$iso" -inspect | grep Audio | cut -d':' -f2 ) >>"$txtfile"
echo "	Advertised Subtitles (English, French, etc.):" $(./umd2mkv -iso "$iso" -inspect | grep Subtitle | cut -d':' -f2 | paste -sd, -) >>"$txtfile"
echo "	Special Features:" >>"$txtfile"
echo "	Advertised Aspect Ratio:" >>"$txtfile"
echo "	Number of Discs:" >>"$txtfile"
echo "	Is this a loose disc? (yes or no):" >>"$txtfile"
echo "	Misc. Comments:" >>"$txtfile"
echo "" >>"$txtfile"
echo "Physical Metadata:" >>"$txtfile"
echo "	Outer Ring Mastering Code:" >>"$txtfile"
echo "	Outer Ring Mastering SID Code:" >>"$txtfile"
echo "	Outer Ring Toolstamp:" >>"$txtfile"
echo "	Inner Ring Mastering Code:" >>"$txtfile"
echo "	Inner Ring Mastering SID Code:" >>"$txtfile"
echo "	Inner Ring Toolstamp:" >>"$txtfile"
echo "	Data Side Mould SID Code:" >>"$txtfile"
echo "" >>"$txtfile"
echo "	CRC32:" $(crc32 "$iso") >>"$txtfile"
echo "	MD5:" $(md5sum "$iso" | awk '{ print $1 }') >>"$txtfile"
echo "	SHA1:" $(sha1sum "$iso" | awk '{ print $1 }') >>"$txtfile"
echo "	Size (in bytes):" $(wc -c < "$iso") >>"$txtfile"
echo "" >>"$txtfile"
echo "PSP Information:" >>"$txtfile"
echo "	Method of Dumping (USB or name of app used): $method" >>"$txtfile"
echo "	PSP Model/CFW Used: $rig" >>"$txtfile"

