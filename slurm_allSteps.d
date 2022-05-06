#!/bin/bash
#SBATCH --ntasks=1                
#SBATCH --partition=titan
#SBATCH --job-name=intraAln # Job name
#SBATCH --error=aa_intraAln_all.err
#SBATCH --output=aa_intraAln_all.out
#SBATCH --cpus-per-task=12
#SBATCH --gres=gpu:6
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=15GB

module load matlab
module load cuda-8.0.61-gcc-4.9.4-rv3d2jh


matlab -nodisplay < dynamoDMT/aa_crop_n_average.m
matlab -nodisplay < dynamoDMT/aa_intraAln.m
matlab -nodisplay < dynamoDMT/aa_alignIntraAvg.m
matlab -nodisplay < dynamoDMT/aa_alignAllParticles.m


