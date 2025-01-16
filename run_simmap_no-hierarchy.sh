#!/bin/bash

for i in {1..50}
do
    sbatch run_job.sh Rscript analysis/simmap_no-hierarchy.R $i
done
