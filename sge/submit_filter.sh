#!/bin/bash

SAMPLE=$1
shift
~/bin/submit_jobs.pl --command ~/bin/filterGeno.pl --options "-s $SAMPLE -n .snptest.exclude %file" \
--submit "qsub -cwd -V -N filter_%base" $@