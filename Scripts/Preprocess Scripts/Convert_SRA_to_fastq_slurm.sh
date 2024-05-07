#!/bin/bash 
pwd; date +%d-%b_%H:%M

# allocate a server node and navigate to TEMP dir
# srun --partition=cpu -w "sx041" --job-name='SRA_to_fastq' --ntasks=48 --pty /bin/bash 

# Initializing variables and setting up the environment
	WorkDir='/home/gpfs/o_shinde/Slurm_Job_Space/Scratch_Dir'
	LogDir=${WorkDir}/Logs
	SRA_Path='/home/gpfs/o_shinde/Softwares_Tejus/sratoolkit.3.0.0-ubuntu64/bin'
	Src_Data_Folder='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch/Backup_all_sra_files'
	Data_Folder='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch/New_Data'

# Add project ID here
	ProjectID='PRJNA917836'
	File_ID=${ProjectID}''
	threads_per_job=46
	
	# Run code here
	while IFS= read -r sampleID; do
	    printf "Changing SRA file to fastq.gz file for: ${sampleID} \n"
	    	    
		# make a specific scratch folder;
      	mkdir -vp ${WorkDir}/${sampleID};
	    
	    # convert sra to fastq;
		${SRA_Path}/fasterq-dump  -e ${threads_per_job} ${Src_Data_Folder}/${sampleID}.sra -p -O ${WorkDir}/${sampleID};
		
		# file size before compression ;
		printf '\n Files size before compression \n'
		echo ${sampleID}
		echo $WorkDir
		ls -hs ${WorkDir}/${sampleID}/*.fastq 
		# Compress fastq files 
		gzip ${WorkDir}/${sampleID}/*.fastq 
		# file size after compression 
		printf '\n Files size after compression \n' ;
		ls -hs ${WorkDir}/${sampleID}/*.fastq.gz ;
		printf '\n-------------------------- Compression Done --------------------------\n' ;
		# cp data back ;
		mkdir ${Data_Folder}/SRA_Downloads/${sampleID}/ 
		cp ${WorkDir}/${sampleID}/*.fastq.gz ${Data_Folder}/SRA_Downloads/${sampleID}/ 
		cp ${Data_Folder}/SRA_Downloads/${sampleID}/*.fastq.gz ${Data_Folder}/../Backup_all_fastq_files/ &
		rm -rf ${WorkDir}/${sampleID} 
		printf '\nJob done\n'
			 
	done <  ${Src_Data_Folder}/../Final_SRA_IDs_grouped_lists/SRA_IDs_${File_ID}.txt > ${Data_Folder}/../Bioproject_data/${ProjectID}/SRA_to_FASTq_conversion_log.out

wait
echo 'End program'
date
