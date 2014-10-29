#!/bin/bash

## check for strand alignment problems and flip the affected SNPs

REF_DIR=/well/jknight/reference/1kg/ALL_1000G_phase1integrated_v3_impute
REF_PREFIX=ALL_1000G_phase1integrated_v3_chr
REF_SUFFIX=_impute
OUT_PREFIX=

## use shapeit to check strand alignment
for chr in $(seq 1 22)
do 
	shapeit -check -P chr${chr}.unphased --input-ref $REF_DIR/$REF_PREFIX$chr$REF_SUFFIX.hap.gz $REF_DIR$REF_PREFIX$chr$REF_SUFFIX.legend.gz  $REF_DIR$REF_PREFIX.sample --output-log $OUT_PREFIXchr${chr}.alignments
done

## create lists of SNPs to flip and exclude
for chr in $(seq 1 22)
do
	cat chr$chr.alignments.snp.strand | grep "strand" | cut -f 3 | uniq > chr$chr.strand_flip.lst
	cat chr$chr.alignments.snp.strand | grep "missing" | cut -f 3 | uniq > chr$chr.missing.lst
done

## flip strand and exclude SNPs missing in reference panel using plink
for chr in $(seq 1 22)
do
	plink --noweb --file chr$chr.unphased --flip chr$chr.strand_flip.lst --exclude chr$chr.missing.lst --recode --out chr$chr.unphased.aligned --make-bed
done