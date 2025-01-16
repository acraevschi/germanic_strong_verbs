#!/bin/bash

for i in {1..50}
do
    sbatch run_job.sh Rscript analysis/simmap_verb_hierarchy.R $i
done
