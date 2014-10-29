# Imputing and filtering genotypes
This repository contains scripts for imputing and filtering genotypes with 
[IMPUTE2](http://mathgen.stats.ox.ac.uk/impute/impute_v2.html). Other software tools 
used include [plink](http://pngu.mgh.harvard.edu/~purcell/plink/) for pre-processing,
[shapeit](http://www.shapeit.fr/) for pre-phasing and 
[snptest](https://mathgen.stats.ox.ac.uk/genetics_software/snptest/snptest.html) for QC.

Some of these scripts were written for use on an SGE cluster and contain commands to
submit jobs to the cluster. These submission scripts are appropriate for the environment
they were written in but may need to be adapted to run in other environments.
The SGE specific scripts are contained in the [./sge](sge) sub-directory. This directory
also contains wrappers for the more general scripts in the top level directory. 

Note that it is assumed that genotypes are stored in ped files, one file per chromosome. 
File names are assumed to follow the convention `chr{chromosome name}.unphased.ped` 
with corresponding map files in the same directory.

**The workflow outlined below only deals with autosomes. 
Imputation of SNPs on sex chromosomes will require some changes.**

## Reference panel
The IMPUTE2 website provides several 
[reference datasets](http://mathgen.stats.ox.ac.uk/impute/impute_v2.html#reference) 
for download. This includes all files required for imputation.

## Pre-phasing genotypes
Prior to to the actual imputation we use [shapeit](http://www.shapeit.fr/) to phase 
the study genotypes. This allows phasing of entire chromosomes, 
rather than the small chunks used for imputation, and allows for faster 
imputation afterwards.

### Strand alignment
**The code in this section is available as a script [from this repository](alignStrand.sh).**

Before the study genotypes can be phased it is important to ensure that alleles 
in the study as well as the reference panel are reported on the same strand. 
Here we use `shapeit`'s `-check` option to generate a problem report for the study genotypes.

```sh
for chr in $(seq 1 22)
do 
	shapeit -check -P chr${chr}.unphased --input-ref $REF_PREFIX$chr$REF_SUFFIX.hap.gz $REF_PREFIX$chr$REF_SUFFIX.legend.gz  $REF_PREFIX.sample --output-log chr${chr}.alignments
done
```

From this we can extract a list of all SNPs that need to have their strand flipped or
are absent from the reference panel and need to be removed.

```sh
for chr in $(seq 1 22)
do
	cat chr$chr.alignments.snp.strand | grep "strand" | cut -f 3 | uniq > chr$chr.strand_flip.lst
	cat chr$chr.alignments.snp.strand | grep "missing" | cut -f 3 | uniq > chr$chr.missing.lst
done
```

Now we can use `plink` to write ped files with properly aligned strands and SNPs 
that are missing in the reference panel excluded.
```sh
for chr in $(seq 1 22)
do
	plink --noweb --file chr$chr.unphased --flip chr$chr.strand_flip.lst --exclude chr$chr.missing.lst --recode --out chr$chr.unphased.aligned --make-bed
done
```

### Phasing
The (binary) ped files created above can then be used as input for phasing with `shapeit`. 
The [getHaplotypes](sge/getHaplotypes.sh) script can be used to submit the necessary 
jobs to the cluster. Assuming that the ped files are located in the current working 
directory and that phased haplotypes should be written to the `phased/` 
sub-directory, the following command will generate the necessary jobs on the cluster:

```sh
getHaplotypes.sh . phased
```
Further arguments to `shapeit` can be passed as additional arguments at the end. 
Note that this makes assumptions about the location of the reference panel files 
and the variables at the top of the script may have to be changed if a different 
reference panel should be used. 

## Imputation
The phased haplotypes obtained above can be used as input to `IMPUTE2`, 
which can then impute genotypes from the reference panel with a single iteration. 
Imputation is carried out for small regions of the genome rather than entire chromosomes. 
The [imputeChunks](sge/imputeChunks.pl) script can automatically partition the 
genome into 5MB chunks and generate the corresponding imputation jobs on an SGE cluster
(*the command used for job submission can be customised on the command-line*).

## Quality control
Once genotypes have been imputed they have to be screened for low quality imputations
so that these can be removed. Here we use `snptest` to generate quality metrics for
all variants. The [submit_snptest](sge/submit_snptest.pl) script will generate useful summaries
from imputed genotypes. By default jobs for several chunks can be generated and submitted to
an SGE cluster using this script. To run `snptest` locally instead use `--submit ""`.
The submission script expects four arguments that specify a common prefix and common suffix
for the files with imputed genotypes, followed by the name of the sample and 
output file.

The resulting summary files can then be used to identify SNPs that should be excluded.
A list of poor quality genotypes can be obtained with the [getExclusions](getExclusions.pl)
script. This provides facilities to specify upper and lower bounds on the values allowed
for columns in the summary file. All SNPs with at least one value outside the specified ranges 
will be written to an exclusion file. This file, together with all imputed genotypes, 
will then serve as input to [filterGeno.pl], which in turn produces
a genotype file with all genotypes that were marked for exclusion removed.

## Combining results
Once low quality genotypes have been removed the chunks of imputed genotypes can be merged
into larger files, e.g. one per chromosome, using [mergeChunks.pl].

## Preparing imputed genotypes for use with Matrix-eQTL
To convert the genotyping data into a format that can be used with Matrix-eQTL the 
[gen2me](jknightlab/genotype-tools/gen2me.pl) script can be used.
