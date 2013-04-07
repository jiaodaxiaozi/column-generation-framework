#!/bin/bash

PATHSRC="sndlib-networks-xml"

rm -f *.rwa

for item in $( ls ../$PATHSRC/ | tr "/" "\n" | sed 's/.xml//g' ) ; do

	SRC=../$PATHSRC/$item.xml
	DST=$item.rwa
	echo "converting $SRC  --> $DST"
	xsltproc rwa.xslt $SRC > $DST
	awk -f validate.awk $DST
done
