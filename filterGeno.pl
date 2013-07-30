#!/usr/bin/perl

## Take sample and genotype files and remove all exclusions (samples and SNPs)

use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use IO::Zlib;

sub usage {
	print basename($0) . " [options] <file_1>[ file_2[ file_3[ ...]]]\n";
	print "  file_i: Genotype file\n";
	print " Options:\n";
	print "   --samples | -s <file>: Sample file.\n";
	print "   --exclude | -e <file>: File with sample exclusion list.\n";
	print
	  "   --include | -i <file>: File with list of samples to include. If present only samples that are listed in this file and not listed in the exclusion file are written to the output files.\n";
	print
	  "   --snps | -n <suffix>: Suffix for SNP exclusion file. [.exclude_snp]\n";
	print "   --prefix | -p <file prefix>: Prefix for SNP exclusion files. [exclusions/]\n";
	print
	  "   --write-sample | -w: Flag indicating whether a filtered sample file should be written. [no]\n";
	print "   --output | -o <directory>: Output directory. [filtered]\n";

	exit;
}

my (
	$status,      @files,   $sampleFile, $exSample, %exSNP,
	$writeSample, $snpSuf,  $outDir,     %exclude,  $line,
	@entry,       @columns, %include,    $inSample, $suffix,
	$prefix
);
$snpSuf      = '.exclude_snp';
$writeSample = '';
$outDir      = 'filtered';
$prefix = "exclusions/";

$status = GetOptions(
	"samples|s=s"    => \$sampleFile,
	"exclude|e=s"    => \$exSample,
	"snps|n=s"       => \$snpSuf,
	"write-sample|w" => \$writeSample,
	"output|o=s"     => \$outDir,
	"include|i=s"    => \$inSample,
	"prefix|p=s"     => \$prefix
);
@files = @ARGV;

usage() unless $status and @files;

## read sample exclusions
if (defined $exSample) {
	open EX, $exSample or die "Cannot read $exSample: $!";
	@entry = <EX>;
	chomp @entry;
	@exclude{@entry} = map { 1 } @entry;
	close EX;
}

## read list of selected samples
if (defined $inSample) {
	open IN, $inSample or die "Cannot read $inSample: $!";
	@entry = <IN>;
	chomp @entry;
	@include{@entry} = map { 1 } @entry;
	close IN;
}

## read sample file
open SAMPLE, $sampleFile or die "Cannot read $sampleFile: $!";
if ($writeSample) {
	die "File exists: $outDir/$sampleFile" if -e "$outDir/$sampleFile";
	open OUT, ">$outDir/" . basename($sampleFile)
	  or die "Cannot write $outDir/$sampleFile: $!";
}
## skip first two lines
$line = <SAMPLE>;
if ($writeSample) {
	print OUT $line;
}
$line = <SAMPLE>;
if ($writeSample) {
	print OUT $line;
}
@columns = (0 .. 4);
while ($line = <SAMPLE>) {
	chomp $line;
	@entry = split /\s/, $line;
	if (not $exclude{ $entry[0] } and (not %include or $include{$entry[0]})) {
		@columns = (@columns, (5 + ($. - 3) * 3) .. (5 + ($. - 2) * 3 - 1));
		if ($writeSample) {
			print OUT "$line\n";
		}
	}
}
close OUT;

## process all genotype files
for my $geno (@files) {
	## read SNP exclusions
	open EX, $prefix . basename($geno) . $snpSuf or die "Cannot read $geno$snpSuf: $!";
	## skip comments
	while(defined *EX and $line = <EX> and $line =~ /^#/){}
	chomp $line;
	@entry = <EX>;
	chomp @entry;
	%exSNP = map { (split(/\t/, $_))[0] => 1 } @entry;
	$exSNP{(split(/\t/, $line))[0]} = 1;
	close EX;

	if($geno !~ /\.gz$/){
		$suffix = '.gz';
	}
	else{
		$suffix = '';
	}
	tie *GENO, 'IO::Zlib', $geno, "rb" or die "Cannot read $geno: $!";
	die "File exists: $outDir/$geno" if -e "$outDir/$geno";
	tie *OUT, 'IO::Zlib', "$outDir/" . basename($geno) . $suffix, 'wb' 
		or die "Cannot write $outDir/$geno: $!";
	while (<GENO>) {
		chomp;
		@entry = split /\s/;
		if (not $exSNP{ $entry[1] } and not $exSNP{ $entry[0] }) {
			print OUT join(' ', @entry[@columns]) . "\n";
		}
	}
	close OUT;
	close GENO;
}

