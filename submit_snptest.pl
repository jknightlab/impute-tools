#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

sub usage {
	print STDERR basename($0) . " [options] <genotypes>\n";
	print STDERR
	  "   genotypes: One or more files with (imputed) genotyping data.\n";
	print STDERR " Options:\n";
	print STDERR "   --sample | -s: Sample file to use.\n";
	print STDERR "   --output | -o: Output directory. [.]\n";
	print STDERR "   --path | -p: Path to SNPTEST executable. [~/bin]\n";
	print STDERR
	  "   --options | -t: SNPTEST options. [\"-summary_stats_only -hwe\"]\n";
	print STDERR
	  "   --submit | -u: Command and options to use for job submission. [\"qsub -cwd -V -b y\"]\n";

	exit;
}

my ($sample, $out, $opt, $sub, $status, $base, $path);
$sub = 'qsub -cwd -V -b y';
$out = '.';
$opt = '-summary_stats_only -hwe';
$path = '~/bin';

$status = GetOptions(
	"sample|s=s"  => \$sample,
	"output|o=s"  => \$out,
	"options|t=s" => \$opt,
	"submit|u=s" => \$sub,
	"path|p=s" => \$path 
);

if(!$status or @ARGV == 0){
	usage();
}

my $cmd = "$sub $path/snptest $opt";
for my $geno (@ARGV){
	$base = basename($geno);
	system("$cmd -data $geno $sample -o $out/$base.snptest"); 
}