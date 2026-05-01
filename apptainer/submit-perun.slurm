#!/bin/bash
#SBATCH --job-name=             # Job name
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=GPU
#SBATCH --account=          # Account name
#SBATCH --qos=              # QoS name
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --ntasks=1

# Activate scratch (ONE LINE!)
#source .activate_scratch

echo Dont submit from apptainer directory!!!
# srun --cpu-bind=none bash apptainer/run-apptainer-script.sh ...
