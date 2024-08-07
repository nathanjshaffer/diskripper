# diskripper

Collection of scripts to automate ripping and transcoding of video and audio disks.  When configured properly, the system will automatically rip any media disc inserted into a cd/dvd rom.  The system can have multiple disc drives and it will determine which drive is being used.  This means on a capable enough system, multiple dives can be used simultaneously.  After ripping the disc, the files will be moved to the appropriate directory.  In the case of a blu-ray disc, before moving the file, the system can can transcode with ffmpeg to create a substantially smaller file.

install.sh contains a lot of setup commands to prepare the system for atoumation of ripping discs.  This includes creating the udev rules to detect disk insertion, installing and configuring abcde, makemkv, ffmpeg, nvidia cuda, and a number of helper utilities and librearies.  This script will also download and update the bash scripts from the github repo.  

This repo was started as a way to easily set up my system if I needed to do a fresh install, but I am working towards making it a more general purpose setup to make it easy for anyone to set up a similar system reguardless of hardware.

## A word of Caution:

This script installs a lot of utilities including the nvidia linux kernal.  I would not recommend installing this on a computer you need to for other work as it may break things.

if you find that some of your hardware stops working such as networking or soundcards, you probably need to install the kernal extras modules.  The NVIDIA installer switches to an NVIDIA  enabled kernal, but doesn't install any of the extras modules that include a lot of drivers for peripherals.  The script will attempt to download the correct module but doesn't install it.  

The command:
```
uname -r
``` 
this will return the current kerenl version.  
running:

```
sudo apt install linux-modules-extra-$(uname -r)-nvidia
```
should install the correct modules that apt downloaded before rebooting.  if that doesn't work, download the file from http://security.ubuntu.com/ubuntu/pool/main/l/linux-nvidia/linux-modules-extra-<kernal version>-nvidia_<kernal version>_amd64.deb
note that the amd64 version is for 64bit systems, make sure you have the correct version for your architecture.


## INSTALL:

After cloning to folder  run:
```
sudo ./install.sh -c
```

Then:
```
sudo ./install.sh -i
```
To only download and reinstall updated bash scripts from the repo:
```
sudo ./install.sh -bg
```

To download, build and install ffmpeg:
```
install -f <Ver>
```
Version number is optional.  if left empty it will use version number defined in config file

## TV RENAMING:
The system currently can't discern between TV and Movie discs.  To help with that, there is a helper function in the dvdrip script to quickly move and rename the files ripped from a TV disc.


  dvdrip episodes 
  usage:
 
    -T        -test move, print command without moving files
    -i        -array of directory paths containing tv episodes.
                  ex. -i "/movie_path_/Friends Disc1|/movie_path_/Friends Disc2"
    -n        -Name of TV show
    -s        -Season number
    
  example:
    if you have a season of friends in the directory */movie_path_/Friends/Friends-Disc1* and */movie_path_/Friends/Friends-Disc2*, then run the command:
```
 dvdrip episodes -n "Friends" -i "/movie_path_/Friends/Friends-Disc1|/movie_path_/Friends/Friends-Disc2" -s "1"
```
                                  
Directories will be processed in the order given and files will be processed in order alphabetically within each directory.  
This results in file naming: 
  */tv_outdir/Friends/season 1/Friends S1E1.mkv*
  */tv_outdir/Friends/season 1/Friends S1E2.mkv*
  *...*

*tv_outdir* is defined in the config file.
