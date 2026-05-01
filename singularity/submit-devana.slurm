#!/bin/bash
#SBATCH --account=            # ACCOUNT
#SBATCH --job-name=           # JOB_NAME
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gpus=4
#SBATCH --time=48:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --mem=64G


# Activate scratch (ONE LINE!)
# source .activate_scratch

module load singularity


echo Dont submit from singularity directory!!!
# srun bash singularity/run-singularity-script.sh ...
