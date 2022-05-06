#!/bin/bash

echo "$1 this is dir"

for filename in $1*.txt
do
	noPrefix=$(echo $filename | awk -F $1 '{print $2}')
	echo "$noPrefix"
	newName="$(echo "$noPrefix" | sed -e "s/$2$//").txt"
	echo "$newName"
	mv $1{$noPrefix,$newName}
done	
