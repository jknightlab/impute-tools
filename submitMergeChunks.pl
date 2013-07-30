#!/usr/bin/perl

## Submit jobs to merge impute2 output for all chunks for a range of chromosomes

use strict;
use warnings;
use File::Basename;

sub usage{
	print STDERR basename($0) . " <prefix> <suffix> <chromosome> <output>\n";
	print STDERR "  prefix: Base of file names to merge\n";
	print STDERR "  suffix: Suffix of file names to merge\n";
	print STDERR "  chromosome: List of chromosome names to process.\n";
	print STDERR "  output: Prefix for output files\n";
	
	exit;
}

usage() if @ARGV != 4;

my ($prefix, $suffix, $chromStr, $out) = @ARGV;
$chromStr =~ s/chr//g;
my @chrom;

for my $chr (split /,/, $chromStr){
	if($chr =~ /(\d+)-(\d+)/){
		push @chrom, ($1 .. $2);
	}
	else{
		push @chrom, $chr;
	}
}

for my $chr (@chrom){
	system("qsub -V -cwd -N merge_chr$chr ~/bin/mergeChunks.pl $prefix$chr. $suffix $out" . basename($prefix) . "$chr$suffix");	
}
