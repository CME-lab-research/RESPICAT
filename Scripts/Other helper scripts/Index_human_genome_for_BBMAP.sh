#!/bin/bash 
#SBATCH --job-name=fastqc_on_fastq.gz_files
#SBATCH --ntasks=1
##SBATCH --mem=100GB
#SBATCH --mail-user=tejus.shinde@medunigraz.at
#SBATCH --partition=debug

printf '\nStart program '

# Setting conda path to a variable
	BBMAP='/home/gpfs/o_shinde/Softwares_Tejus/bbmap'
	ReferenceDir='/home/gpfs/o_shinde/References_local/GRCh38_human_genome'
	LogDir=$ReferenceDir/Logs; mkdir $LogDir; 

#SBATCH --error=$LogDir/fastqc-%j.err
#SBATCH --output=$LogDir/fastqc-%j.out

# Run the code here # Build a human ref index for BBMAP
	# Indexing
	bash $BBMAP/bbmap.sh ref=$ReferenceDir/GRCh38_latest_genomic.fna

printf '\nEnd program \n'