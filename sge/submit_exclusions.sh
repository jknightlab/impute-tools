#!/bin/bash

~/bin/submit_jobs.pl --command ~/bin/getExclusions.pl --options "--name rsid \
-f missing_data_proportion=0,0.02 -f info=0.5,1 -f all_maf=0.01,1 \
-f average_maximum_posterior_call=0.9,1 -f cohort_1_hwe=1e-10,1 --explain %file" \
--submit "qsub -cwd -V -N getExclusions_%base -o %file.exclude" $@