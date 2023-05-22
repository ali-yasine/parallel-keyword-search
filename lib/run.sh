#!/bin/bash

#SBATCH --job-name=pks
#SBATCH --partition=gpu
#SBATCH --gres=gpu:v100d32q:1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=64000
#SBATCH --time=0-6:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=aay22@mail.aub.edu

## set the environment modules

module purge
module load gcc/9.1.0
module load cuda

## compile the c++ code
make clean
make

## execute the c++ job
./pks