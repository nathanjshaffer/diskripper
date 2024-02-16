#!/bin/bash

cddir="/home/homeserver.media/Music/.incoming_music/"
discname=$(blkid -o value -s LABEL /dev/cdrom)
discname=$(tr '_' ' ' <<<"$discname")
discname=$(echo "$discname" | tr '[:upper:]' '[:lower:]')
arr=( $discname )
discname=${arr[@]^}
logfile="${logdir}${discname}.log"

sleep 10

echo `date '+%s'` >> /home/nathan/diskrip.log
