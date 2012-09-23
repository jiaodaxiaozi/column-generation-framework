#!/bin/bash

PATHSRC="."
PATHOUT="./OUT"




INPUTNETWORK=( US*.dat  )


NUMBERINPUT=${#INPUTNETWORK[@]}


for (( i = 0 ; i < $NUMBERINPUT ; i ++ )) ; do


	item=${INPUTNETWORK[ ${i} ]%.*}

	SRC=$PATHSRC/$item.dat
	OUT=$PATHOUT/$item.out
	ERR=$PATHOUT/$item.err

	echo "input from " $SRC  " output to " $OUT " error to " $ERR 

	bsub -n 4 -q "long" -M 25165824 -J $item -oo $OUT -eo $ERR  oplrun -deploy -D input="$SRC" ../../solver.mod model.dat
	
#	sleep 3
done
