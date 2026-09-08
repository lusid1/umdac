param(
    [Parameter(Mandatory = $true)]
    [string]$iso
)

# ------------------------------------------------------------
# Read a file inside an ISO (ISO9660)
# ------------------------------------------------------------
function Read-IsoFile {
    param(
        [string]$isoPath,
        [string]$internalPath
    )

    $bytes = [System.IO.File]::ReadAllBytes($isoPath)
    $sectorSize = 2048
    $rootOffset = 16 * $sectorSize

    for ($i = $rootOffset; $i -lt $bytes.Length - 34; $i++) {
        $len = $bytes[$i]
        if ($len -lt 34) { continue }

        $record = $bytes[$i..($i + $len - 1)]
        $nameLen = $record[32]
        $name = [System.Text.Encoding]::ASCII.GetString($record[33..(33 + $nameLen - 1)])

        if ($name -eq $internalPath.Trim('/')) {
            $extent = [BitConverter]::ToInt32($record[2..5], 0)
            $size   = [BitConverter]::ToInt32($record[10..13], 0)
            $offset = $extent * $sectorSize
            return $bytes[$offset..($offset + $size - 1)]
        }
    }

    return $null
}

# ------------------------------------------------------------
# Parse PARAM.SFO (native)
# ------------------------------------------------------------
function Parse-SFO {
    param([byte[]]$bytes)

    $magic = [System.Text.Encoding]::ASCII.GetString($bytes[0..3])
    if ($magic -ne "PSF") { return "" }

    $keyTableOffset = [BitConverter]::ToInt32($bytes[8..11], 0)
    $valTableOffset = [BitConverter]::ToInt32($bytes[12..15], 0)
    $entries        = [BitConverter]::ToInt32($bytes[16..19], 0)

    $pos = 20
    $title = ""

    for ($i = 0; $i -lt $entries; $i++) {
        $keyOffset = [BitConverter]::ToInt16($bytes[$pos..($pos+1)], 0)
        $fmt       = [BitConverter]::ToInt16($bytes[$pos+2..($pos+3)], 0)
        $valLen    = [BitConverter]::ToInt32($bytes[$pos+4..($pos+7)], 0)
        $valMax    = [BitConverter]::ToInt32($bytes[$pos+8..($pos+11)], 0)
        $valOffset = [BitConverter]::ToInt32($bytes[$pos+12..($pos+15)], 0)
        $pos += 16

        $key = ""
        $k = $keyTableOffset + $keyOffset
        while ($bytes[$k] -ne 0) {
            $key += [char]$bytes[$k]
            $k++
        }

        if ($key -eq "TITLE") {
            $v = $valTableOffset + $valOffset
            $title = [System.Text.Encoding]::UTF8.GetString($bytes[$v..($v + $valLen - 1)])
        }
    }

    return $title.Trim()
}

# ------------------------------------------------------------
# CRC32 (native)
# ------------------------------------------------------------
function Get-CRC32 {
    param([string]$path)

    $table = @(0..255 | ForEach-Object {
        $crc = $_
        0..7 | ForEach-Object {
            if ($crc -band 1) { $crc = (0xEDB88320 -bxor ($crc -shr 1)) }
            else { $crc = ($crc -shr 1) }
        }
        $crc
    })

    $crc = 0xFFFFFFFF
    $stream = [System.IO.File]::OpenRead($path)

    while (($b = $stream.ReadByte()) -ne -1) {
        $crc = $table[($crc -bxor $b) -band 0xFF] -bxor ($crc -shr 8)
    }

    $stream.Close()
    return "{0:X8}" -f (-bxor $crc 0xFFFFFFFF)
}

# ------------------------------------------------------------
# Extract UMD fields
# ------------------------------------------------------------
$UMD_DATA_BYTES  = Read-IsoFile $iso "UMD_DATA.BIN"
$UMD_VIDEO_BYTES = Read-IsoFile $iso "UMD_VIDEO/PARAM.SFO"
$UMD_AUDIO_BYTES = Read-IsoFile $iso "UMD_AUDIO/PARAM.SFO"

$UMD_DATA  = if ($UMD_DATA_BYTES)  { Parse-SFO $UMD_DATA_BYTES }  else { "" }
$UMD_VIDEO = if ($UMD_VIDEO_BYTES) { Parse-SFO $UMD_VIDEO_BYTES } else { "" }
$UMD_AUDIO = if ($UMD_AUDIO_BYTES) { Parse-SFO $UMD_AUDIO_BYTES } else { "" }

# ------------------------------------------------------------
# Title selection
# ------------------------------------------------------------
$TITLE = $UMD_VIDEO
if ($UMD_AUDIO.Length -gt $TITLE.Length) { $TITLE = $UMD_AUDIO }

# ------------------------------------------------------------
# Title sanitization (SAFE VERSION)
# ------------------------------------------------------------
$TITLESAFE = $TITLE
$TITLESAFE = $TITLESAFE -replace "[/\\?%*:|""<>]", " "
$TITLESAFE = $TITLESAFE -replace "[^ -~]", ""
$TITLESAFE = $TITLESAFE -replace "\s+", " "
$TITLESAFE = $TITLESAFE.Trim()

# ------------------------------------------------------------
# ASCII check
# ------------------------------------------------------------
$ASCITITLE = ($TITLESAFE.ToCharArray() | Where-Object { [int]$_ -lt 128 }) -join ""

$SERIAL = ""
if ($ASCITITLE -ne $TITLESAFE) {
    $SERIAL = "[$UMD_DATA] "
}

# ------------------------------------------------------------
# Audio & Subtitle tracks (umd2mkv)
# ------------------------------------------------------------
$inspect = & umd2mkv.exe -iso "$iso" -inspect

$AUDIO_TRACKS = ($inspect | Select-String "Audio") |
    ForEach-Object { $_.ToString().Split(":")[1].Trim() }

$Langs = ($AUDIO_TRACKS -split ",") |
    ForEach-Object { $_.Split("=")[-1].Trim() } |
    ForEach-Object { $_ -replace "\s", "" } -join ","

$Langs = "($Langs)"

$Subtitles = ($inspect | Select-String "Subtitle") |
    ForEach-Object { $_.ToString().Split(":")[1].Trim() } -join ", "

# ------------------------------------------------------------
# CRC32 / MD5 / SHA1 / size
# ------------------------------------------------------------
$CRC32 = Get-CRC32 $iso
$MD5   = (Get-FileHash -Algorithm MD5  $iso).Hash.ToLower()
$SHA1  = (Get-FileHash -Algorithm SHA1 $iso).Hash.ToLower()
$Size  = (Get-Item $iso).Length

# ------------------------------------------------------------
# Suggested filename
# ------------------------------------------------------------
$suggested_name = "$TITLESAFE $Langs $SERIAL[$CRC32].iso"

# ------------------------------------------------------------
# Output
# ------------------------------------------------------------
Write-Host ""
Write-Host "File Name......: $(Split-Path $iso -Leaf)"
Write-Host "Suggested Name.: $suggested_name"
Write-Host "UMD_DATA Title.: $UMD_DATA"
Write-Host "UMD_VIDEO Title: $UMD_VIDEO"
Write-Host "UMD_AUDIO Title: $UMD_AUDIO"
Write-Host "Audio Tracks...: $AUDIO_TRACKS"
Write-Host "Subtitles......: $Subtitles"
Write-Host "CRC32..........: $CRC32"
Write-Host "MD5............: $MD5"
Write-Host "SHA1...........: $SHA1"
Write-Host "Size in bytes..: $Size"
Write-Host ""
