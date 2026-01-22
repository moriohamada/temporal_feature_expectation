#!/usr/bin/env bash
#SBATCH -J fs_split
#SBATCH -o logs/glm-%j.out
#SBATCH -e logs/glm-%j.err
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH -c 5
#SBATCH -t 0-06:00
#SBATCH --mem=32G
#SBATCH --array=0-3225

module load matlab/R2024b
matlab -nosplash -nodesktop -r " hpc_glm_wrapper($SLURM_ARRAY_TASK_ID); exit;"

