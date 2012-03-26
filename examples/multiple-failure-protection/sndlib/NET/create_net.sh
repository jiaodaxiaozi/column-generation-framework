#!/bin/bash

PATHSRC="RWA"

#rm -f *.net
rm -f *.ran


for item in $( ls ../$PATHSRC/geant.rwa ) ; do

	SRC=$item
	
	filename=$(basename $item)
	extension=${filename##*.}
	filename=${filename%.*}

	DST=$filename.ran

	echo "converting $SRC  --> $DST"
	
	awk -f rwa2ran.awk $SRC   > $DST

	for (( percent = 0 ; percent <= 100 ; percent +=10 )); do

		echo "converting $DST  --> $filename-$percent.net" 

		awk -v percent=$percent -f ran2net.awk $DST   > $filename-$percent.net
	done
done

rm -f *.ran
