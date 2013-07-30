#!/usr/bin/perl

## Merge impute2 output for several chunks of the same chromosome

use strict;
use warnings;
use File::Basename;

sub usage{
	print STDERR basename($0) . " <prefix> <suffix> <output>\n";
	print STDERR "  prefix: Base of file names to merge\n";
	print STDERR "  suffix: Suffix of file names to merge\n";
	print STDERR "  output: Name of output file\n";
	print STDERR "\nThis script will merge all files with names matching <prefix>*<suffix>\n";
	
	exit;
}
usage() unless @ARGV == 3;

my $prefix = shift;
my $suffix = shift;
my $out = shift;

my @files = <$prefix*$suffix>;
system("cat @files > $out");