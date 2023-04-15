#!/usr/bin/env bash
#SBATCH -J fullMdl
#SBATCH -o logs/glm-%j.out
#SBATCH -e logs/glm-%j.err
#SBATCH -N 1
#SBATCH -c 6
#SBATCH -t 0-12:00
#SBATCH --mem=48G
#SBATCH --array=4250-8200

module load matlab/R2024b
#matlab -nosplash -nodesktop -r " fit_EL_ridge_glm_hpc($SLURM_ARRAY_TASK_ID); exit;"
matlab -nosplash -nodesktop -r " fit_full_ridge_glm_hpc($SLURM_ARRAY_TASK_ID); exit;"

