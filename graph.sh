#!/bin/bash

DATADIR="/home/leftyfb/Desktop/temp/"
WEBDIR="/var/www/"
 
#define the desired colors for the graphs
DOWNLOAD_COLOR="#3366CC"
UPLOAD_COLOR="#EE66CC"
PING_COLOR="#CC0000"
SIZE="--height=200 --width=750"
 
rrdgraph(){
 rrdtool graph $WEBDIR/temp_$1.png $SIZE --start -"$1" \
 DEF:Download=$DATADIR/temp.rrd:download:AVERAGE \
 DEF:Upload=$DATADIR/temp.rrd:upload:AVERAGE \
 DEF:Ping=$DATADIR/temp.rrd:ping:AVERAGE \
 LINE1:Download$ATEMP_COLOR:"Ping" \
 LINE2:Upload$WTEMP_COLOR:"Download" \
 LINE3:Ping$WTEMP_COLOR:"Upload" 
}
 
for i in 1h 4h 1d 1w 1m 1y ; do
 rrdgraph $i
done
