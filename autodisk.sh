#!/bin/bash

echo "autodisk " `date '+%s'` > /home/nathan/diskrip.log
echo /usr/local/bin/cdrip.sh | at now
{
  if [ "$ID_CDROM_MEDIA_DVD" -eq "1" ]; then
    #echo /usr/local/bin/dvdrip.sh | at now
    #echo "dvd insert" > "/var/log/diskrip/insert" 
  fi
}
{
  if [ "$ID_CDROM_MEDIA_CD" -eq "1" ]; then
    echo /usr/local/bin/cdrip.sh | at now
    #echo "cd insert" > "/var/log/diskrip/insert" 
  fi
}
