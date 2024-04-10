#!/bin/bash

# see udev events - sudo udevadm monitor

# lookup udev variables - udevadm info --query=all --name=/dev/#name


if [ `id -u` -ne 0 ]
  then echo "ERROR: Please run as sudo"
  exit
fi

source ./config


install=true
update=false

while getopts ":uif:m:" flag
do
    case ${flag} in
        u) update=true
           install=false
           ;;
        i) install=true
           update=false
           ;;
        f) ffmpegVer=${OPTARG}
           ;;
        m) makemkvVer=${OPTARG}
           ;;
        *)
                echo 'Error in command line parsing' >&2
                exit 1
    esac
done


homedir="/home/${user}"

if [[ $install == true ]]; then
 echo "install"
  apt-get install libdvd-pkg
  dpkg-reconfigure libdvd-pkg
  apt-get install regionset libavcodec-extra dvdbackup yasm lsdvd autofs abcde at flac mkvtoolnix
  apt-get install build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev qtbase5-dev zlib1g-dev libx264-dev libx265-dev

  systemctl enable --now atd
  

  echo 'SUBSYSTEM=="block", ENV{ID_CDROM}=="1", ENV{ID_TYPE}=="cd", ACTION=="change", RUN+="/usr/local/bin/autodisk '"'"'%E(DEVNAME)'"'"'"' | tee /etc/udev/rules.d/autodisk.rules

  udevadm control --reload

fi


if [[ $install == true ]] || [[ $update == true ]]; then

  wget -O ./cdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/cdrip
  wget -O ./dvdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/dvdrip
  wget -O ./bdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/bdrip
  wget -O ./autodisk https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/autodisk
  
  echo -e '#!/bin/bash'"\n" > /tmp/cdrip
  echo "user=\"${user}\"
ripdir=\"${CD_ripdir}\"
remotedir=\"${CD_remotedir}\"
outformat=\"${CD_outformat}\"" >> /tmp/cdrip
  cat ./bdrip >> /tmp/cdrip
  
  
  echo '-e #!/bin/bash'"\n" > /tmp/dvdrip
  echo "user=\"${user}\"
ripdir=\"${DVD_ripdir}\"
remotedir=\"${DVD_remotedir}\"
outformat=\"${DVD_outformat}\"" >> /tmp/dvdrip
  cat ./bdrip >> /tmp/dvdrip
  
  
  echo -e '#!/bin/bash'"\n" > /tmp/bdrip
  echo "user=\"${user}\"
ripdir=\"${BD_ripdir}\"
remotedir=\"${BD_remotedir}\"
outformat=\"${BD_outformat}\"" >> /tmp/bdrip
  cat ./bdrip >> /tmp/bdrip
  
  
  echo -e '#!/bin/bash'"\n" > /tmp/autodisk
  echo "user=\"${user}\"" >> /tmp/autodisk
  cat ./bdrip >> /tmp/autodisk


  install -c -D -m 755 /tmp/autodisk /usr/local/bin/
  install -c -D -m 755 /tmp/dvdrip /usr/local/bin/
  install -c -D -m 755 /tmp/cdrip /usr/local/bin/
  install -c -D -m 755 /tmp/bdrip /usr/local/bin/
  
  
  if ! ffmpeg -version | grep -q "ffmpeg version ${ffmpegVer}";
  then
    echo "downloading ffmpeg"
    wget https://ffmpeg.org/releases/ffmpeg-${ffmpegVer}.tar.xz
    tar -xvf ffmpeg-${ffmpegVer}.tar.xz
    
    cd ffmpeg-${ffmpegVer}
    echo "$PWD"
    
    ./configure --enable-gpl --enable-libx264 --enable-libx265
    make
    make install
    rm -rf /tmp/ffmpeg

    cd../
  else
    echo "ffmpeg is current version. Skipping..."
  fi

  if [ ! -d "./makemkv-bin-${makemkvVer}" ];
  then
    wget https://www.makemkv.com/download/makemkv-bin-${makemkvVer}.tar.gz
    wget https://www.makemkv.com/download/makemkv-oss-${makemkvVer}.tar.gz

    tar -xvf makemkv-bin-${makemkvVer}.tar.gz
    tar -xvf makemkv-oss-${makemkvVer}.tar.gz

    cd makemkv-oss-${makemkvVer}
    ./configure
    make
    make install

    cd ../makemkv-bin-${makemkvVer}
    make
    make install

    cd ../
  else
    echo "makemkv is current version. Skipping..."
  fi
fi



