OS=$(uname -s)

# Enterprise Linux derivitives
if [ -f /etc/redhat-release ]; then
    echo "Release: $(cat /etc/redhat-release)"
    sudo dnf install -y epel-release
    sudo dnf install -y coreutils 
    sudo dnf install -y perl-String-CRC32
    sudo dnf install -y ffmpeg-free 
    sudo dnf install -y genisoimage
    sudo dnf install -y golang
    sudo dnf install -y git

    # Check and install umd2mkv
    umd2mkv=$(which umd2mkv)
    if [ -z "$umd2mkv" ]; then
        echo "Installing umd2mkv..."
        git clone https://github.com/kacboy/umd2mkv.git
        cd umd2mkv
        go build ./cmd/umd2mkv
        sudo cp umd2mkv /usr/local/bin/
        sudo cp umd2mkv /usr/bin/
        cd ..
    fi

fi

# Debian/Ubuntu derivitives
if [ -f /etc/debian_version ]; then
    echo "Release: Ubuntu/Debian ($(cat /etc/debian_version))"
    sudo apt-get update -y
    sudo apt-get install -y coreutils             
    sudo apt-get install -y libarchive-zip-perl
    sudo apt-get install -y ffmpeg
    sudo apt-get install -y genisoimage
    sudo apt-get install -y golang
    sudo apt-get install -y git

    # Check and install umd2mkv
    umd2mkv=$(which umd2mkv)
    if [ -z "$umd2mkv" ]; then
        echo "Installing umd2mkv..."
        git clone https://github.com/kacboy/umd2mkv.git
        cd umd2mkv
        go build ./cmd/umd2mkv
        sudo cp umd2mkv /usr/local/bin/
        sudo cp umd2mkv /usr/bin/
        cd ..
    fi
fi

echo "OS.....: $OS"
echo "ifoinfo: $(which isoinfo)"
echo "ffmpeg.: $(which ffmpeg)"
echo "umd2mkv: $(which umd2mkv)"
echo "crc32..: $(which crc32)"
echo "md5sum.: $(which md5sum)"
echo "sha1sum: $(which sha1sum)"
