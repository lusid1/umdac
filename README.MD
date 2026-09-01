# UMDAC Utilities

## Requirements
The following tools must be installed and in the path
- isoinfo
- umd2mkv
- ffmpeg
- crc32
- md5sum
- sha1sum



## umdinfo.sh
takes the isofile as a parameter and outputs useful information such as suggested filename and file hashes.

Usage:
``` 
./umdinfo.sh /path/to/umd.iso
```
Example:

```
./umdinfo.sh "/mnt/f/UMDVIdeo (En)/Alien (Canadian).ISO"

File Name......: Alien (Canadian).ISO
Suggested Name.: Alien (eng,fra)[86bbe4d1].iso
UMD_DATA Title.: Alien
UMD_VIDEO Title: Alien
UMD_AUDIO Title: 
Audio Tracks...: 00=eng (English), 01=fra (French)
Subtitles......: English [eng], Spanish [spa], French [fra]
CRC32..........: 86bbe4d1
MD5............: 66d48aa491fb201882f87b20c2410abe
SHA1...........: 1c591a42d94c47ef0b15ae585ff35eebcf78c64f
Size in bytes..: 1788215296
```

# umdrename.sh 
Renames a UMD Video ISO to the following naming convention:
```
<title> (audo tracks) [ Serial ] [ CRC32 ].iso
```
Serial is only included for non-ascii titles

Usage:

To rename a file and leave it in its current location:
```
./umdrename.sh /path/to/umd.iso
```

To leave the original filename, but copy a renamed version to an output folder:
```
./umdrename.sh /path/to/umd.iso -copy2dir=/path/to/directory
```

To move and rename the original file to an output folder:
```
./umdrename.sh /path/to/umd.iso -move2dir=/path/to/directory
```

# batch-rename.sh
Calls rename for every UMD in a given path, recursively

Usage:

To rename all UMD files in place:
```
./batch-rename.sh /path/to/isos
```

To leave the original files in place, but copy renamed versions to an output folder:
```
./batch-rename.sh /path/to/isos -copy2dir=/path/to/directory
```

To move and rename the original files to an output folder:
```
./batch-rename.sh /path/to/isos -move2dir=/path/to/directory
```

# makesheet.sh
Creates a new info sheet with some values pre-populated

Note: edit the script variables to reflect your name and setup

```
./makesheet.sh /path/to/umd.iso
```

