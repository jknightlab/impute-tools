#!/bin/bash

OUT=$1
shift
snptest -summary_stats_only -data $* -o $OUT
