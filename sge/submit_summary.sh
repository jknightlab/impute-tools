#!/bin/bash

PREFIX=$1
SUFFIX=$2
SAMPLE=$3
OUT=$4
for file in $PREFIX*$SUFFIX
do
qsub -cwd -V getSummary.sh $OUT $file $SAMPLE
done