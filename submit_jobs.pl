#!/usr/bin/perl

## Wrappper to genrate cluster job submissions for a command-line program

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Cwd qw(realpath);

sub usage {
	print STDERR basename($0) . " [options] <input>\n";
	print STDERR
	  "   input: One or more files that will be used to replace variables in the commandline options. One job will be generated for each file.\n";
	print STDERR " Options:\n";
	print STDERR "   --command | -c: command to run (including full path).\n";
	print STDERR
	  "   --options | -o: Arguments to pass to 'command'. The name of the current input file can be referenced by '%file'\n";
	print STDERR
	  "   --submit | -s: Command and options to use for job submission. [\"qsub -cwd -V -b y\"]\n";

	print STDERR "\nRecognised command line variables:\n";
	print STDERR '  %file: fully qualified name of the input file.' . "\n";
	print STDERR '  %base: name of the input file (without the path component).' . "\n";
	print STDERR '  %dir: absolute path of the directory containing the input file.' . "\n";
	
	exit;
}

my ($opt, $sub, $status, $cmd, $base, $dir);
$sub = 'qsub -cwd -V -b y';
$opt = '';

$status = GetOptions(
	"options|o=s" => \$opt,
	"submit|s=s" => \$sub,
	"command|c=s" => \$cmd 
);

if(!$status or not defined $cmd){
	usage();
}

$cmd = "$sub $cmd $opt";
my $instance;
for my $file (@ARGV){
	$instance = $cmd;
	$file = realpath($file);
	$base = basename $file;
	$dir = dirname $file;
	$instance =~ s/%file/$file/g;
	$instance =~ s/%base/$base/g;
	$instance =~ s/%dir/$dir/g;
	system("$instance"); 
}