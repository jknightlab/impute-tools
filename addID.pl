#! /usr/bin/perl

## fill in missing SNP IDs with genomic coordinates

use strict;
use warnings;
use File::Basename;
use IO::Zlib;

sub usage{
	print STDERR basename($0) . " <chrom> <file>\n";
	print STDERR "  chrom: Chromosome name to use for variants in the file.\n";
	print STDERR "  file: Genotyping file.\n";
	
	exit;	
}

usage() if @ARGV != 2;
my ($chrom, $input) = @ARGV;
my (@entry, $id);

if($input =~ /\.gz$/){
	tie *IN, 'IO::Zlib', $input, "rb";
}
else{
	open IN, $input or die "Cannot read $input: $!";	
}

while(<IN>){
	chomp;
	@entry = split /\s/;
	$id = $chrom . ':' . $entry[2];
	if($entry[0] eq '---'){
		$entry[0] = $id;
	}
	if($entry[1] eq '---'){
		$entry[1] = $id;
	}
	print join(' ', @entry) . "\n";
}
close IN;
