#!/usr/bin/perl

## Call genotypes from impute2 output. 
## Note that sites should be filterd beforehand to remove low quality imputations.
##
## Author: Peter Humburg, 2012

use warnings;
use strict;
use File::Basename;
use IO::Zlib;
use Getopt::Long;

sub usage{
	print STDERR basename($0) . " [options] <files>\n";
	print STDERR "   files: List of impute2 output files.\n";
	print STDERR " Options:\n";
	print STDERR "   --dosage | -d: Output dosage estimates rather than calls.\n";
	
	
	exit;
}

my ($status, $dosage);
$status = GetOptions("dosage|d" => \$dosage);

if(not @ARGV){
	usage();
}

my (@entry, $call);
for my $file (@ARGV){
	if($file =~ /\.gz$/){
		tie *IN, 'IO::Zlib', $file, 'rb' or (warn("Unable to read $file: $!") and next);
	}
	else{
		open IN, $file or (warn("Unable to read $file: $!") and next);
	}
	while(<IN>){
		chomp;
		@entry = split /\s/;
		if($entry[0] =~ /(\d+):\d+/){
			$entry[0] = $1;
		}
		print join(" ", @entry[0..4]);
		
		for(my $i = 5; $i < @entry; $i += 3){
			$call = 0;
			if($dosage){
				$call = $entry[$i+1] + 2*$entry[$i+2];
			}
			elsif($entry[$i+1] > $entry[$i] and $entry[$i+1] > $entry[$i+2]){
				$call = 1;
			}
			elsif($entry[$i+2] > $entry[$i] and $entry[$i+2] > $entry[$i+1]){
				$call = 2;
			}
			print " $call";
		}
		print "\n";
	}
	close IN;
}