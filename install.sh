#!/bin/bash
source ./config
# see udev events - sudo udevadm monitor

# lookup udev variables - udevadm info --query=all --name=/dev/#name


if [ `id -u` -ne 0 ]
  then echo "ERROR: Please run as sudo"
  exit
fi

config=false
sysconf=false
update=false
getrepo=false
buildnvcodec=false
makemkv=false
ffmpeg=false
remotefs=""
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "options:"
   echo "h              Print this Help."
   echo "c              create config files"
   echo "s              configure systemfiles and apt packages."
   echo "r path         setup remote nfs directory"
   echo "b              install ripping scripts to system directory."
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

while getopts ":ihcsbgfmnr:" flag
do
  case ${flag} in
      
    h) # display Help
       Help
       exit;;
    c) config=true;;
    s) sysconf=true;;
    r) remotefs=${OPTARG};;
    b) bins=true;;
    g) getrepo=true;;
    f) ffmpeg=true
       getopts_get_optional_argument $@
       if [[ ${OPTARG} != "" ]]; then
       ffmpegVer=${OPTARG}
       fi ;;
    
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
  bins=true
  buildnvcodec=true
  makemkv=true
  ffmpeg=true
fi


if [[ $config == true ]]; then
config_file
fi

if [[ $useconfiginstall == true ]]; then
  if [[ hardware_encoding == true ]]; then
    buildnvcodec=true
  fi
  sysconf=true
  update=true
  bins=true
  getrepo=true
  makemkv=true
  ffmpeg=true
fi

config_file() {

echo "Setting up config options:"


if [ ! -f "./config" ]; then 
  wget -O ./autodisk https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/config 
fi

read -p "Set User for file ownership? <y/n> " setoption

if [[ setoption == "y" ]]; then
  read -p "Enter User:" user
fi

#####
read -p "Set directory to rip raw files into before processing? <y/n> " setoption

if [[ setoption == "y" ]]; then
  read -p "Enter directory:" DVD_ripdir
fi
#####
read -p "Set directory to move video files after conversion/naming? <y/n> " setoption

if [[ setoption == "y" ]]; then
  read -p "Enter directory:" movie_outdir
fi
#####
read -p "Set Directory abcde should rip files to? <y/n> " setoption

if [[ setoption == "y" ]]; then
  read -p "Enter directory:" CD_ripdir
fi
#####



  rep_str=`grep "user" ./config`
  sed -i "s/$rep_str/user=$user/" ./config

  rep_str=`grep "DVD_ripdir" ./config`
  sed -i "s/$rep_str/DVD_ripdir=$DVD_ripdir/" ./config

  rep_str=`grep "movie_outdir" ./config`
  sed -i "s/$rep_str/movie_outdir=$movie_outdir/" ./config

  rep_str=`grep "CD_ripdir" ./config`
  sed -i "s/$rep_str/CD_ripdir=$CD_ripdir/" ./config

#####

}

config_system() {
 echo "config system"
 
  apt-get install avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan
  apt-get install libdvd-pkg
  dpkg-reconfigure libdvd-pkg
  apt-get install regionset libavcodec-extra dvdbackup yasm lsdvd abcde at flac git
  apt-get install build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev qtbase5-dev zlib1g-dev libx264-dev libx265-dev
  apt-get install mkvtoolnix

  systemctl enable --now atd
  
  echo 'SUBSYSTEM=="block", ENV{ID_CDROM}=="1", ENV{ID_TYPE}=="cd", ACTION=="change", RUN+="/usr/local/bin/autodisk '"'"'%E(DEVNAME)'"'"'"' | tee /etc/udev/rules.d/autodisk.rules

  udevadm control --reload
  
  echo "PADTRACKS=n
OUTPUTTYPE=flac
OUTPUTDIR=$CD_ripdir
EJECTCD=y
INTERACTIVE=n" > /home/$user/.abcde.conf



}
  

setup_remote_fs() {
  apt-get install autofs
  echo "/nfs   /etc/auto.nfs" >> /etc/auto.master
  echo "diskripremote   -fstype=nfs4   $remotefs" > /etc/auto.nfs
  
  sed -i 's/NEED_IDMAPD=/NEED_IDMAPD=yes/' /etc/default/nfs-common
  service autofs reload
  ls /nfs/diskripremote
}



install_binaries() {
  echo "install binaries"
  
  if [[ $getrepo == true ]]; then
    echo "download binaries from repo"
    wget -O ./cdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/cdrip
    wget -O ./dvdrip https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/dvdrip
    wget -O ./autodisk https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/autodisk
  fi  
  
  if [ ! -f "./config" ]; then 
    wget -O ./autodisk https://raw.githubusercontent.com/nathanjshaffer/diskripper/main/config 
  fi
  
  chown -R $user:$user ./
    
  install -D -m 755 -t  /usr/share/diskripper ./config
  install -c -D -m 755 ./autodisk /usr/local/bin/
  install -c -D -m 755 ./dvdrip /usr/local/bin/
  install -c -D -m 755 ./cdrip /usr/local/bin/

}

build_nv_codec() {

  echo "build nv-codec"
  pdir="$PWD"
  mkdir ./nv-codec-headers_build && cd ./nv-codec-headers_build
  git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
  cd nv-codec-headers
  make && sudo make install
  cd "$pdir"
  
  apt-get install linux-headers-$(uname -r)
  apt-key del 7fa2af80
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
  dpkg -i cuda-keyring_1.1-1_all.deb
  apt-get update
  apt-get install cuda-toolkit
  apt-get install nvidia-gds
  apt-get install nvidia-utils-550-server
  apt-get install libnvidia-decode-550-server
  apt-get install libnvidia-encode-550-server
  
  apt-get install --download-only linux-headers-$(uname -r)-nvidia
  apt-get install --download-only linux-modules-extra-$(uname -r)-nvidia
  
  #wget http://security.ubuntu.com/ubuntu/pool/main/l/linux-nvidia/linux-modules-extra-$(uname -r)-nvidia_xxx_amd64.deb
  
  echo "Make sure linux-modules-extra-$(uname -r)-nvidia is installed, then reboot to finish setup"

}

install_ffmpeg() {
if test -f ./ffmpeg-${ffmpegVer}.tar.xz; then
      echo "downloading ffmpeg Ver. ${ffmpegVer}"
      wget https://ffmpeg.org/releases/ffmpeg-${ffmpegVer}.tar.xz
  fi
      pdir="$PWD"
      tar -xvf ffmpeg-${ffmpegVer}.tar.xz
      
      cd ffmpeg-${ffmpegVer}
      
      export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}

      
      if [[ hardware_encoding == true ]]; then
        ./configure --enable-nonfree --enable-gpl --enable-libx264 --enable-libx265 --enable-nvenc --enable-cuda-nvcc --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --disable-static --enable-shared 
        else
        ./configure --enable-gpl --enable-libx264 --enable-libx265
      fi
      
      make
      make install
      rm -rf /tmp/ffmpeg
      ldconfig
      cd "$pdir"
}

install_makemkv() {
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
}


if [[ $sysconf == true ]]; then
config_system
fi

if [[ $remotefs != false ]]; then
setup_remote_fs
fi

if [[ $bins == true ]]; then
install_binaries
fi

if [[ $buildnvcodec == true ]]; then
build_nv_codec
fi
  

if [[ $ffmpeg == true ]]; then
install_ffmpeg
fi

if [[ $makemkv == true ]]; then
install_makemkv
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



