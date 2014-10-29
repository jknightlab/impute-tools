#!/bin/bash

## infer haplotypes from genotyping data using shapeit
## usage: getHaplotypes.sh <input dir> <output prefix> [additional shapeit parameters]

## environment variables used to specify location and name patterns
## for genetic map and reference panel
REF_DIR=/well/jknight/reference/1kg/ALL_1000G_phase1integrated_v3_impute
REF_PREFIX=ALL_1000G_phase1integrated_v3
REF_SEP=_chr
REF_SUFFIX=_impute
REF_SUF2=.gz
MAP_DIR=/well/jknight/reference/1kg/ALL_1000G_phase1integrated_v3_impute
MAP_PREFIX=genetic_map_chr
MAP_SUFFIX=_combined_b37.txt
MAP_SUF2=
BIN_DIR=/well/jknight/software/cluster3/bin
INPUT_FORMAT=bed
INPUT_PREFIX=chr
INPUT_SUFFIX=.unphased.aligned

INPUT=$1
OUTPUT=$2
shift 2

for chr in $(seq 1 22)
do
	qsub -cwd -V -pe shmem 4 -b y -N chr$chr.shapeit $BIN_DIR/shapeit \
	--input-$INPUT_FORMAT $INPUT/$INPUT_PREFIX$chr$INPUT_SUFFIX --thread 4 \
	--input-map $MAP_DIR/$MAP_PREFIX$chr$MAP_SUFFIX$map_SUF2 \
	--output-max $OUTPUT$chr.phased --output-graph $OUTPUT$chr.hgraph \
	--output-log $OUTPUT$chr.log \
--input-ref $REF_DIR/$REF_PREFIX$REF_SEP$chr$REF_SUFFIX.hap$REF_SUF2 \
	$REF_DIR/$REF_PREFIX$REF_SEP$chr$REF_SUFFIX.legend$REF_SUF2 $REF_DIR/$REF_PREFIX.sample $*
done