#!/bin/bash
echo "$1"
echo "$2"
echo "$3"
cd $1
rm $3modfiles.txt
ls $2 >> $3modfiles.txt
