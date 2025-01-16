#!/bin/bash

for i in {1..50}
do
    sbatch run_job.sh Rscript simulation/sim_history.R $i
done
