#!/bin/bash
# Script to count particles in particles folder for quick checking

for folder in particles/*
do
	count=`ls $folder/particle* | wc -l`
	echo $folder $count
done
