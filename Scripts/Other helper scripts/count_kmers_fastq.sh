#!/bin/bash 
#SBATCH --job-name=Count_kmers_fastq_file
#SBATCH --ntasks=1
##SBATCH --mem=10GB
#SBATCH --mail-user=tejus.shinde@medunigraz.at
#SBATCH --partition=debug

# Setting conda path to a variable
	BBMAP='/home/gpfs/o_shinde/Softwares_Tejus/bbmap'
	dataDir='/home/gpfs/o_shinde/Slurm_Job_Space/P1/demo_Run_PRJNA707099/Raw_Data'
	LogDir=$dataDir/Logs; mkdir $LogDir; 
	outDir=$dataDir/clean_reads

#SBATCH --error=$LogDir/fastqc-%j.err
#SBATCH --output=$LogDir/fastqc-%j.out

	cd $dataDir

# Run the code here
	#for f in $dataDir/*.fastq.gz ; do
		#FILENAME=`basename ${f%%.*}`;

		# size before
		#ls -hs ${FILENAME}.fastq.gz
		ls -hs SRR13867774*
		#printf '\nCleaning sample '
		#echo ${FILENAME};

		# run fastqc
		bash $BBMAP/bbcountunique.sh in=$dataDir/SRR13867774_1.fastq.gz in2=$dataDir/SRR13867774_2.fastq.gz outu=$LogDir/

		ls -hs $LogDir
	#done
