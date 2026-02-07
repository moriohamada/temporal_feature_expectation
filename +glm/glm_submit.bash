#!/usr/bin/env bash
#SBATCH -J fs_split
#SBATCH -o logs/glm-%j.out
#SBATCH -e logs/glm-%j.err
#SBATCH -p cpu
#SBATCH -N 1
#SBATCH -c 5
#SBATCH -t 0-08:00
#SBATCH --mem=48G
#SBATCH --array=0-3225
#SBATCH --mail-type=FAIL        
#SBATCH --mail-user=morio.hamada.19@ucl.ac.uk

cd /nfs/nhome/live/morioh/Documents/MATLAB/final_pipeline/

module load matlab/R2022a
matlab -nosplash -nodesktop -r "glm.hpc_glm_wrapper($SLURM_ARRAY_TASK_ID); exit;"
