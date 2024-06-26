#!/bin/bash
source ./config

# see udev events - sudo udevadm monitor

# lookup udev variables - udevadm info --query=all --name=/dev/#name


if [ `id -u` -ne 0 ]
  then echo "ERROR: Please run as sudo"
  exit
fi


sysconf=false
update=false
dlrepo=false
buildnvcodec=false
makemkv=false
ffmpeg=false

Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "options:"
   echo "h              Print this Help."
   echo "s              configure systemfiles and apt packages."
   echo "b              install ripping scripts."
   echo "d              download updated ripping scripts from repo."
   echo "f  opt<ver>    build and install ffmpeg.  optional version number."
   echo "m  opt<ver>    build and install makemkvcon. option version number."
   echo "n              build nv-codec for gpu acceleration."
   echo
}

getopts_get_optional_argument() {
  eval next_token=\${$OPTIND}
  if [[ -n $next_token && $next_token != -* ]]; then
    OPTIND=$((OPTIND + 1))
    OPTARG=$next_token
  else
    OPTARG=""
  fi
}

while getopts ":hsbdfmn" flag
do
  case ${flag} in
      
    h) # display Help
       Help
       exit;;
    s) sysconf=true;;
    b) bins=true;;
    d) dlrepo=true;;
    f) ffmpeg=true
       getopts_get_optional_argument $@
       ffmpegVer=${OPTARG};;
    
    m) makemkv=true
       getopts_get_optional_argument $@ 
       makemkvVer=${OPTARG};;
    n) buildnvcodec=true ;;
    *)
        echo 'Error in command line parsing' >&2
        exit 1
  esac
done

if [ "$opt" = "?" ]
then
  echo "Default option executed (by default)"
  
  sysconf=true
  update=true
  dlrepo=true
  buildnvcodec=true
  makemkv=true
  ffmpeg=true
fi

homedir="/home/${user}"

if [[ $sysconf == true ]]; then
 echo "config system"
  
  apt-get install libdvd-pkg
  dpkg-reconfigure libdvd-pkg
  apt-get install regionset libavcodec-extra dvdbackup yasm lsdvd autofs abcde at flac git
  apt-get install build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev qtbase5-dev zlib1g-dev libx264-dev libx265-dev

  systemctl enable --now atd
  
  echo 'SUBSYSTEM=="block", ENV{ID_CDROM}=="1", ENV{ID_TYPE}=="cd", ACTION=="change", RUN+="/usr/local/bin/autodisk '"'"'%E(DEVNAME)'"'"'"' | tee /etc/udev/rules.d/autodisk.rules

  udevadm control --reload

fi

if [[ $bins == true ]]; then

  echo "install binaries"
  
  if [[ $dlrepo == true ]]; then
    echo "download binaries from repo"
    wget -O ./cdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/cdrip
    wget -O ./dvdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/dvdrip
    wget -O ./bdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/bdrip
    wget -O ./autodisk https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/autodisk
  fi  
  
  if [ ! -f "./config" ]; then 
    wget -O ./autodisk https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/config 
  fi
    
  install -D -t /usr/share/diskripper -m 755 ./config
  install -c -D -m 755 ./autodisk /usr/local/bin/
  install -c -D -m 755 ./dvdrip /usr/local/bin/
  install -c -D -m 755 ./cdrip /usr/local/bin/
  install -c -D -m 755 ./bdrip /usr/local/bin/
fi

if [[ $buildnvcodec == true ]]; then
  echo "build nv-codec"
  pdir="$PWD"
  mkdir ./nv-codec-headers_build && cd ./nv-codec-headers_build
  git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
  cd nv-codec-headers
  make && sudo make install
  cd "$pdir"
fi

if [[ $ffmpeg == true ]]; then
  if [ ! ffmpeg -version | grep -q "ffmpeg version ${ffmpegVer}" ]; then
      echo "downloading ffmpeg"
      
      pdir="$PWD"
      wget https://ffmpeg.org/releases/ffmpeg-${ffmpegVer}.tar.xz
      tar -xvf ffmpeg-${ffmpegVer}.tar.xz
      
      cd ffmpeg-${ffmpegVer}
      
      ./configure --enable-gpl --enable-libx264 --enable-libx265 --enable-nvenc
      make
      make install
      rm -rf /tmp/ffmpeg

      cd "$pdir"
    else
      echo "ffmpeg is current version. Skipping..."
  fi
fi

if [[ $makemkv == true ]]; then
  if [ ! -d "./makemkv-bin-${makemkvVer}" ]; then
      echo "downloading makemkv"
      pdir="$PWD"
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

      cd "$pdir"
    else
      echo "makemkv is current version. Skipping..."
  fi
fi

if [[ $buildblurayinfo == true ]]; then
  echo "build bluray-info"
  pdir="$PWD"
  mkdir ./bluray_info && cd ./bluray_info
  git clone https://github.com/beandog/bluray_info.git
  cd ./bluray_info
  make && sudo make install
  cd "$pdir"
fi



