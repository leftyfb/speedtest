#!/bin/bash
# created rules from http://rrdwizard.appspot.com/rrdcreate.php

tmpfile=$(mktemp)
DATADIR="~/speedtest"
if [ -d $DATADIR ] ; then
 mkdir -p $DATADIR
fi

#define the desired colors for the graphs
COLOR="#3366CC"
DOWNLOAD_COLOR="#3366CC"
UPLOAD_COLOR="#EE66CC"
PING_COLOR="#CC0000"
SIZE="--height=200 --width=500"

if [ ! -f $DATADIR/download.rrd ] ; then
rrdtool create $DATADIR/download.rrd --step '300' 'DS:download:GAUGE:600:1:150' 'RRA:MIN:0.5:1:105120'
fi
if [ ! -f $DATADIR/upload.rrd ] ; then
rrdtool create $DATADIR/upload.rrd --step '300' 'DS:upload:GAUGE:600:1:50' 'RRA:MIN:0.5:1:105120'
fi
if [ ! -f $DATADIR/ping.rrd ] ; then
rrdtool create $DATADIR/ping.rrd --step '300' 'DS:ping:GAUGE:600:1:15000' 'RRA:MIN:0.5:1:105120'
fi

timeout 120 speedtest-cli --simple > $tmpfile 

if [ $? = "1" ] ; then
	exit 0
fi

pingval=$(echo "($(grep Ping $tmpfile|awk '{print $2}')+0.5)/1"|bc)
pingformat=$(grep Ping $tmpfile|awk '{print $3}')

downval=$(echo "($(grep Down $tmpfile|awk '{print $2}')+0.5)/1"|bc)
downformat=$(grep Down $tmpfile|awk '{print $3}'|sed 's/its//g')

upval=$(echo "($(grep Upload $tmpfile|awk '{print $2}')+0.5)/1"|bc)
upformat=$(grep Upload $tmpfile|awk '{print $3}'|sed 's/its//g')

echo -e "$(date) $pingval,$downval,$upval" >> $DATADIR/speed.log

rrdupdate(){
 rrdtool update $DATADIR/download.rrd --template download N:$downval
 rrdtool update $DATADIR/upload.rrd --template upload N:$upval
 rrdtool update $DATADIR/ping.rrd --template ping N:$pingval
}

rrdgraph(){
 if [ "$1" = "ping" ] ; then
  	CF=MAX
	VTITLE="--vertical-label milliseconds"
 else
	CF=MIN
	VTITLE="--vertical-label Mbit/s"
 fi
 rrdtool graph $DATADIR/$1_$2.png $SIZE $VTITLE \
 --start -"$2" \
 DEF:$1=$DATADIR/$1".rrd":$1:$CF \
 LINE3:$1#3366CC:"$1" >/dev/null
}

rrdupdate download
rrdupdate upload
rrdupdate ping

for i in 1h 4h 1d 1w 1m 1y ; do
 rrdgraph download $i
 rrdgraph upload $i
 rrdgraph ping $i
 rrdtool graph $DATADIR/all_$i.png $SIZE --start -"$i" \
 DEF:Download=$DATADIR/download.rrd:download:MIN \
 DEF:Upload=$DATADIR/upload.rrd:upload:MIN \
 LINE3:Download#3366CC:download \
 LINE3:Upload#EE66CC:upload > /dev/null
done

rm $tmpfile
