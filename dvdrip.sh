#!/bin/bash

logdir="~/.var/log/diskrip/"
moviedir="/home/homeserver.media/Videos/.incoming_video/"
mkvdir="~/vobs"

#####

discname=$(blkid -o value -s LABEL /dev/cdrom)
discname=$(tr '_' ' ' <<<"$discname")
discname=$(echo "$discname" | tr '[:upper:]' '[:lower:]')
arr=( $discname )
discname=${arr[@]^}
logfile="${logdir}${discname}.log"

echo "ripping disc $discname" >> "$logfile"

makemkvcon --progress=stdout --minlength=2500 --decrypt mkv disc:0 all $mkvdir >> "$logfile"; 

sleep 2;

# Rename mkv Files

find $mkvdir -maxdepth 1 -iname '*.mkv' -print0 | sort -z | while IFS= read -r -d '' file; 
do 
    namestatus=""

    if [[ "$mkvname" == *"$-"* ]]; then

        mkvname=${file#*$mkvdir}
        mkvname=${mkvname%%-*}
 
        mv "$logfile" "${logdir}${mkvname}.log"
        logfile="${logdir}${mkvname}.log"
        mkvname="${mkvname}"
        namestatus="mkv name"
    else
        mkvname="${discname}"
        namestatus="disc name"
    fi

    i=1
    if test -f "${moviedir}${mkvname}.mkv";
    then
        while test -f "${moviedir}${mkvname}_$i.mkv"; do
            ((i=i+1))
        done
        mkvname="${mkvname}_$i"
    fi

    mkvname="${mkvname}.mkv"
    echo "Renaming $file to ${mkvname}.mkv" >> "$logfile";

    mv "$file" "${moviedir}${mkvname}"

    echo "File = ${moviedir}${mkvname} ----  Disc = ${discname} ---- using:${namestatus}" >> "${logdir}riplist.txt"
done

sleep 2 ;
eject -r
