#!/usr/bin/perl

## generate list of records to exclude from file

use strict;
use warnings;
use File::Basename;
use Getopt::Long;

sub usage {
	print basename($0) . " [options] <summary>\n";
	print
	  "  summary: Tab delimited file with column names in the first line.\n";
	print " Options:\n";
	print
	  "   --filter | -f <tag>=<min>,<max>: <tag> is the name of a column in the file. <min> and <max> are the minimum and maximum value to be retained respectively.\n";
	print
	  "   --name | -n <string>: Name of column that contains the row names.\n";
	print
	  "   --comment | -c <string>: Comment character. All lines starting with this will be ignored. [#]\n";
	  print "   --explain | -e: Flag indicating whether a list of filters that each site failed should be added to the output.\n";
	exit;
}

my ($status, %filter, $id, $comment, $file, @entry, %column, $explain, @reason, $remove);
$comment = '#';
$explain = '';
$status  = GetOptions(
	"filter|f=s%" => sub { $filter{$_[1]} = [split /,/, $_[2]] },
	"name|n=s"    => \$id,
	"comment|c=s" => \$comment,
	"explain|e!" => \$explain
);
$file = shift;
usage() if not $status or not defined $file;

## print header with information on filters
for my $field (keys %filter){
	print $comment . "FILTER $field: min = " . @{$filter{$field}}[0] . ", max = " . @{$filter{$field}}[1] . "\n";  
}


open IN, $file or die "Cannot read $file: $!";

while (<IN>) {
	next if /^$comment/;
	chomp;
	@entry = split /\s/;
	## first non comment line should have column names
	if(not %column){
		@column{@entry} = 0..$#entry;
		$id = $column{$id};
		next;
	}
	@reason = ();
	$remove = '';
	for my $field (keys %filter){
		
		if($entry[$column{$field}] < @{$filter{$field}}[0] or $entry[$column{$field}] > @{$filter{$field}}[1]){
			$remove = 1;
			if($explain){
				push @reason, $field;
			}
			else{
				last;
			}
		}
	}
	if($remove){
		print "$entry[$id]";
		if($explain){
			print "\t" . join(',', @reason);
		}
		print "\n";
	}
}
close IN;