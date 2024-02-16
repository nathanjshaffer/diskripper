#!/bin/bash


if [ `id -u` -ne 0 ]
  then echo "Please run as root"
  exit
fi

ffmpegVer=6.1.1
makemkvVer=1.17.6

install=$true
update=$false

while getopts u:i:f:m flag
do
    case "${flag}" in
        u) update=$true
        install=$false;;
        i) install=$true
        update=$false;;
        f) ffmpegVer=${OPTARG};;
        m) makemkvVer=${OPTARG};;
    esac
done

if [ $install = $true ]
  apt-get install libdvd-pkg
  dpkg-reconfigure libdvd-pkg
  apt-get install regionset libavcodec-extra dvdbackup yasm lsdvd autofs abcde at flac
  apt-get install build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev qtbase5-dev zlib1g-dev

  systemctl enable --now atd


  install -c -D -m 755 ./autodisk /usr/local/bin/
  install -c -D -m 755 ./dvdrip /usr/local/bin/
  install -c -D -m 755 ./cdrip /usr/local/bin/

  echo 'SUBSYSTEM=="block", ENV{ID_CDROM}=="1", ENV{ID_TYPE}=="cd", ACTION=="change", RUN+="/usr/local/bin/autodisk.sh"' | tee /etc/udev/rules.d/autodisk.rules

  udevadm control --reload

fi


if [ $install = $true ] || [ $update = $true ]

  mkdir ~/makemkv
  cd ~/makemkv

  wget https://ffmpeg.org/releases/ffmpeg-${ffmpegVer}).tar.xz
  tar -xvf ffmpeg-${ffmpegVer}).tar.xz
  cd ffmpeg-${ffmpegVer})
  ./configure
  make
  make install
  rm -rf /tmp/ffmpeg

  cd../

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

fi



