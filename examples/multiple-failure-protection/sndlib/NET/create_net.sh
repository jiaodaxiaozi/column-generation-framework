#!/bin/bash

PATHSRC="RWA"

rm -f *.net
rm -f *.ran


for item in $( ls ../$PATHSRC/*.rwa ) ; do

	SRC=$item
	
	filename=$(basename $item)
	extension=${filename##*.}
	filename=${filename%.*}

	DST=$filename.ran

	echo "converting $SRC  --> $DST"
	
	awk -f rwa2ran.awk $SRC   > $DST

	for (( percent = 0 ; percent <= 100 ; percent +=10 )); do

		echo "converting $DST  --> $filename-d$percent-t0-q0.net" 
		awk -v dpercent=$percent -v take3=0 -v take4=0  -f ran2net.awk $DST   > $filename-d$percent-t0-q0.net

	done

	
	echo "converting $DST  --> $filename-d50-t10-q0.net"
    awk -v dpercent=50 -v take3=10  -v take4=0  -f ran2net.awk $DST   > $filename-d50-t10-q0.net

	echo "converting $DST  --> $filename-d50-t20-q10.net"
    awk -v dpercent=50 -v take3=20  -v take4=10  -f ran2net.awk $DST   > $filename-d50-t20-q10.net

    echo "converting $DST --> $filename-node.net"
    awk -v pnode=1 -f ran2net.awk $DST > $filename-node.net
done

rm -f *.ran
