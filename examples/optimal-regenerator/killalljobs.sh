#!/bin/bash

JOBS=($( bjobs | awk '/[0-9]/ { print $1 } ' ))

NJOB=${#JOBS[@]}


for (( i = 0 ; i < $NJOB ; i ++ )) ; do

	echo kill the job ${JOBS[ ${i} ]}
	bkill  ${JOBS[ ${i} ]}

done

