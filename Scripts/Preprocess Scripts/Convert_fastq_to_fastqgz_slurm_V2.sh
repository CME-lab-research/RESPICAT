#!/bin/bash 
#SBATCH --job-name=Compression_loop_for_fastq_files
#SBATCH --ntasks=2
##SBATCH --mem=200GB
#SBATCH --mail-user=tejus.shinde@medunigraz.at
#SBATCH --partition=debug
#SBATCH --cpus-per-task=1

	pwd; date

# Initializing variables and setting up the environment
	WorkDir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project'
	LogDir=$WorkDir/Logs
	ScratchDir=$WorkDir/ScratchDir/$SLURM_JOBID
	Data_Folder='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/Data'

#SBATCH --error=$LogDir/job.%j.err
#SBATCH --output=$LogDir/job.%j.out

# Setting up the SCRATCH space (Scratch space is space on the hard disk drive that is dedicated for storage of temporary user data.)
	printf "Scratch Directory: "
	echo $ScratchDir
	mkdir -vp $ScratchDir; cd $ScratchDir; echo 'In scratch directory now: ' ;pwd
	


# Run code here
	while IFS= read -r line; do
	    printf "File compression for: $line \n"
      # make a specific scratch folder
      mkdir -vp $ScratchDir/$line         
	    
      #printing the contents of the sample folder
      printf "/n Files size before compression /n"
      ls -hs $Data_Folder/SRA_Downloads/$line
      # copy files to scratch dir
	    cp -r $Data_Folder/SRA_Downloads/$line/*.fastq $ScratchDir/$line # Copy data to SCRATCH (for operations with heavy I/O loads)
    	
      # compress cmd here
      gzip $ScratchDir/$line/*.fastq
      printf "\n-------------------------- Compression Done --------------------------\n"
      
      # copy back data
      cp -r $ScratchDir/$line/*.gz $Data_Folder/SRA_Downloads/$line/
      rm -rf $ScratchDir/$line/
      # delete the original sra files
      rm -rf $Data_Folder/SRA_Downloads/$line/*.sra
      #printing the contents of the sample folder
      printf "/n Files size after compression /n"
      ls -hs $Data_Folder/SRA_Downloads/$line 
     
	done < $Data_Folder/Final_SRA_IDs_grouped_lists/Pending_SRA_IDs_PRJEB29918.txt # Check if file exists

# remove the scratch directory 
	cd $WorkDir
	rm -rf $ScratchDir

	echo 'End program'
	date
 