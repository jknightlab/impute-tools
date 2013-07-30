#!/usr/bin/perl

## merge two sets of genotyping data
## Author: Peter Humburg, 2012

use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use IO::Zlib;

sub usage {
	print basename($0) . " [options] <geno_1> <geno_2>\n";
	print "  geno_1: Genotype file for first set.\n";
	print "  geno_2: Genotype file for second set.\n";
	print " Note: geno_1 and geno_2 may be lists of files as long as the number of files in each list is the same.\n";
	print " Options:\n";
	print "   --sample1 | -a <file>: Sample file for first set.\n";
	print "   --sample2 | -b <file>: Sample file for second set.\n";
	print "   --output | -o <prefix>: Prefix for output files\n";
	print
	  "   --columns | -c <int>[,<int>],...]: Columns in sample files to retain. [0,1,2]\n";
	exit;
}

my (
	$status, $sampleA, $sampleB, $prefix, @gtA,    @gtB, @cols,
	$header, $chrom,   $lineA,   $lineB,  @entryA, @entryB
);

@cols = (0, 1, 2);
$status = GetOptions(
	"sample1|a=s" => \$sampleA,
	"sample2|b=s" => \$sampleB,
	"output|o=s"  => \$prefix,
	"columns|c=s" => sub { @cols = split /,/ }
);

if (not $status or @ARGV < 2 or @ARGV % 2) {
	usage();
}

@gtA = @ARGV[ 0 .. (@ARGV / 2 - 1) ];
@gtB = @ARGV[ (@ARGV / 2) .. $#ARGV ];

## merge sample files
open OUT, ">$prefix.sample" or die "Cannot write $prefix.sample: $!";
open IN,  $sampleA          or die "Cannot read $sampleA: $!";
## print header
print OUT join(' ', (split(/\s/, <IN>))[@cols]) . "\n";
print OUT join(' ', (split(/\s/, <IN>))[@cols]) . "\n";

while (<IN>) {
	chomp;
	print OUT join(' ', (split(/\s/))[@cols]) . "\n";
}
close IN;
open IN, $sampleB or die "Cannot read $sampleB: $!";
## skip header
$header = <IN>;
$header = <IN>;
while (<IN>) {
	chomp;
	print OUT join(' ', (split(/\s/))[@cols]) . "\n";
}
close IN;
close OUT;

## read genotype files
for (my $i = 0; $i < @gtA; $i++) {
	my $genoA = $gtA[$i];
	my $genoB = $gtB[$i];
	$genoA =~ /[._](chr[0-9XY]+)[._]/;
	$chrom = $1;
	print "merging $genoA and $genoB\n";
	tie *GENO1, 'IO::Zlib', $genoA, "rb" or die "Cannot read $genoA: $!";
	tie *GENO2, 'IO::Zlib', $genoB, "rb" or die "Cannot read $genoB: $!";
	tie *OUT, 'IO::Zlib', "$prefix.$chrom.txt.gz", "wb"
	  or die "Cannot write $prefix.$chrom.txt.gz: $!";

	while ( defined *GENO1
		and defined *GENO2
		and $lineA = <GENO1>
		and $lineB = <GENO2>) {
		chomp $lineA;
		chomp $lineB;
		@entryA = split /\s/, $lineA;
		@entryB = split /\s/, $lineB;

		if ($entryA[2] == $entryB[2]) {
			print OUT join(' ', (@entryA, @entryB[ 5 .. $#entryB ])) . "\n";
		}
		## skip lines that are only present in one set
		while ($entryA[2] < $entryB[2]) {
			$lineA = <GENO1>;
			last if not defined $lineA;
			chomp $lineA;
			@entryA = split /\s/, $lineA;
		}
		while ($entryB[2] < $entryA[2]) {
			$lineB = <GENO2>;
			last if not defined $lineB;
			chomp $lineB;
			@entryB = split /\s/, $lineB;
		}
	}
	close GENO1;
	close GENO2;
	close OUT;
}
