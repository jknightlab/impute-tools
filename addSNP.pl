#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

sub usage{
	print "zcat <genotypes> | $0 [options] | gzip - > <output>\n";
	print "  <genotypes>: Genotypes in chiamo format.\n";
	print "  <output>: Genotypes in chiamo format with additional variant.\n";
	print "  Options:\n";
	print "    --variant | -v: Tab delimited file with information about variant to add (name, position, alleles).\n";
	print "    --sample | -s: Sample file.\n";
	print "    --carrier | -c: List of sample IDs that carry the variant.\n";
	print "    --exlusions | -e: Sample exclusion list.\n";
	print "    --output-exclusions | -o: Output file for final exclusion list.\n";
	print "    --add | -a: Number of non-carriers to include. [1000]\n";
	print "    --translate | -t: Flag indicating whether exclusion sample IDs need to be translated. [no]\n".
	print "    --column | -i: Column in sample exclusion file that contains sample IDs. [0]\n";
	print "    --liftover | -l: Flag indicating whether coordinates in <genotypes> should be converted to a different genome build. [no]\n";
	print "    --chr: Name of chromosome on which variants in 'genotypes' are located.\n";
	print "    --chain: Name of chain file to use for liftover.\n";
	print "    --lift-prefix: Prefix to use for liftover files. [liftOver_]\n";
	print "    --lift-path: Path to liftover binary. [~/bin]\n";
	
	exit;
}


sub do_liftOver {
	my ($chr, $pos, $chain, $path, $prefix) = @_;
	my $input = $prefix . 'in';
	my $output = $prefix . 'out';
	my $missing = $prefix . 'unmapped';
	my $end = $pos + 1;
	
	## prepare input file
	open LIFT, ">$input" or die "Cannot create temporary file $input: $!";
	print LIFT "$chr\t$pos\t$end\n";
	close LIFT;
	
	system("$path/liftOver $input $chain $output $missing > /dev/null") == 0
		or die "Call to liftOver failed: $?";
	
	## read output
	open LIFT, $output or die "Cannot read temporary file $output: $!";
	my $result = <LIFT>;
	close LIFT;
	chomp $result;
	my @entry = split /\t/, $result;
	if($entry[0] ne $chr){
		warn "Variant maps to different chromosome after conversion.";
		return -1;
	}
	return $entry[1];
}




my ($varFile, $subjFile, $sampleFile, $exFile, $exOut, $add, $translate, $col, $liftover,
    $chain, $prefix, $liftPath, $chr, $status, %sample, 
    %select, @exclude, @var, @entry, $idx, $key, @keys, $help, %id, $exID);

$add = 1000;
$help = '';
$translate = '';
$col = 0;
$liftover = '';
$prefix = 'liftOver_';
$liftPath = '~/bin';

$status = GetOptions('variant|v=s' => \$varFile, 'carrier|c=s' => \$subjFile, 
					 'exclusions|e=s' => \$exFile, 'output-exclusions|o=s' => \$exOut,
					 'add|a:i' => \$add, 'sample|s=s' => \$sampleFile, 'help|h' => \$help,
					 'translate|t!' => \$translate, 'column|i:i' => \$col, 'lift-path:s' => \$liftPath,
					 'liftover|l!' => \$liftover, 'chain=s' => \$chain, 'prefix:s' => \$prefix,
					 'chr=s' => \$chr);

&usage if not $status or @ARGV > 0 or $help;

## read variant file
open VAR, $varFile or die "Cannot read $varFile: $!";
## assume single variant
my $line = <VAR>;
chomp $line;
@var = split /\t/, $line;
close VAR;

## read sample file
open SAMPLE, $sampleFile or die "Cannot read $sampleFile: $!";
while(<SAMPLE>){
	## skip header
	next if $. < 3;
	
	@entry = split /\s/;
	$sample{$entry[1]} = $.;
	if($translate){
		$id{$entry[0]} = $entry[1];
	}
}
close SAMPLE;

## read sample exclusion file
## and remove existing exclusions from sample list
open EXCLUDE, $exFile or die "Cannot read $exFile: $!";
while(<EXCLUDE>){
	next if /^#/;
	chomp;
	@entry = split /\s/;
	if($translate){
		$exID = $id{$entry[$col]};
	}
	else{
		$exID = $entry[$col];
	}
	next unless defined $exID;
	push @exclude, $exID;
	if(exists $sample{$exID}){
		delete $sample{$exID};
	}
}
close EXCLUDE;

## read file with carrier IDs
open SELECT, $subjFile or die "Cannot read $subjFile: $!";
while(<SELECT>){
	chomp;
	$select{$_} = 1 if exists $sample{$_};
}
close SELECT;

## process input genotypes to add variant
while(my $line = <>){
	chomp $line;
	@entry = split /\s/, $line;
	if($liftover){
		$entry[2] = &do_liftOver($chr, $entry[2], $chain, $liftPath, $prefix);
		next if $entry[2] < 0;
		$line = join ' ', @entry;
	}
	print "$line\n" and next if $entry[2] < $var[1];
	
	## add variant
	print "$var[0] $var[0] $var[1] $var[2] $var[3]";
	## iterate through samples, determine their genotype and print it
	foreach my $ind (sort {$sample{$a} <=> $sample{$b}} keys(%sample)){
		if(exists $select{$ind}){
			print " 0 1 0";
		}
		else{
			print " 1 0 0";
		}
	}
	print "\n";
	last;
}

## print remaining SNPs
while($line = <>){
	chomp $line;
	if($liftover){
		@entry = split /\s/, $line;
		$entry[2] = &do_liftOver($chr, $entry[2], $chain, $liftPath, $prefix);
		next if $entry[2] < 0;
		$line = join ' ', @entry;
	}
	print "$line\n";
}

## now that we have the genotypes we need to decide which samples 
## to include for phasing and imputation

## remove all selected samples from sample list
foreach my $ind (keys %select){
	delete $sample{$ind};
}

## choose random samples to include for phasing
for(my $i = 0; $i < $add; $i++){
	@keys = keys %sample;
	$idx = int(rand(scalar @keys));
	$select{$keys[$idx]} = 1;
	delete $sample{$keys[$idx]};
}

## all remaining samples are excluded
@exclude = (@exclude, keys %sample);

## write exclusion file
open OUT, ">$exOut" or die "Cannot write $exOut: $!";
foreach my $ind (@exclude){
	print OUT "$ind\n";
}
close OUT;




