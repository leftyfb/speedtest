#!/bin/bash
# rrdtool create speed.rrd --step '300' 'DS:download:GAUGE:180:U:U' 'DS:upload:GAUGE:180:U:U' 'DS:ping:GAUGE:180:U:U' 'RRA:MIN:0.5:1:105120' 'RRA:MIN:0.5:1:105120' 'RRA:MAX:0.5:1:105120'

tmpfile=$(mktemp)
rrdfile=/home/leftyfb/speed.rrd
timeout 60 speedtest-cli --simple > $tmpfile 
if [ $0 = "1" ] ; then
	exit 0
fi

pingval=$(echo "($(grep Ping $tmpfile|awk '{print $2}')+0.5)/1"|bc)
pingformat=$(grep Ping $tmpfile|awk '{print $3}')

downval=$(echo "($(grep Down $tmpfile|awk '{print $2}')+0.5)/1"|bc)
downformat=$(grep Down $tmpfile|awk '{print $3}'|sed 's/its//g')

upval=$(echo "($(grep Upload $tmpfile|awk '{print $2}')+0.5)/1"|bc)
upformat=$(grep Upload $tmpfile|awk '{print $3}'|sed 's/its//g')

mkfile(){
echo "{
  \"value\": $1,
  \"formatted\": \"$1 $2\"
}"
}

mkfile "$pingval" "$pingformat" |ssh -i /root/.ssh/left-click.id_rsa root@left-click.org "cat > /home/leftyfb/WWW/blog/ping.json"
mkfile "$downval" "$downformat" |ssh -i /root/.ssh/left-click.id_rsa root@left-click.org "cat > /home/leftyfb/WWW/blog/down.json"
mkfile "$upval" "$upformat" |ssh -i /root/.ssh/left-click.id_rsa root@left-click.org "cat > /home/leftyfb/WWW/blog/up.json"
rrdtool update $rrdfile --template download:upload:ping N:$downval:$upval:$pingval
echo -e "$(date) $pingval,$downval,$upval" >> /home/leftyfb/speed.log
rm $tmpfile
