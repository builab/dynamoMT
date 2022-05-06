#!/bin/bash

args=("$@")

cat $3 | while read line || [[ -n $line ]];
do
    a=$(dirname $line)
    echo "$a"
    # suffix=$4
    # echo "$suffix"
	# b=$(echo "$line" | sed -e "s$suffix$//")
    # echo "$b"
	model2point -Contour $1$line $2$a.txt
done
