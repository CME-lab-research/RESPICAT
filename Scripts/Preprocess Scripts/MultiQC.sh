#!/bin/bash 


printf '---------------------- Start program ----------------------\n'
pwd; date

# Initializing variables and setting up the environment
	WorkDir='/home/gpfs/o_shinde/Slurm_Job_Space' 
	LogDir= $WorkDir/Logs/
	ScratchDir=$WorkDir/Scratch_Dir/$SLURM_JOBID
	Project_Dir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/Data'
	Original_Data_Folder='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/Data/SRA_Downloads'
	CondaDir='/home/data/galaxy_tool_dependencies/_conda/bin'

# Setting up the SCRATCH space and log directory(Scratch space is space on the hard disk drive that is dedicated for storage of temporary user data.)
	printf "Scratch Directory: "
	echo $ScratchDir
	mkdir -vp $ScratchDir; cd $ScratchDir; 
	mkdir -vp $LogDir
	#mkdir $ScratchDir/input_files
	printf "\n"

	# Env
	source $CondaDir/activate __multiqc@1.9

	# Run code here
	while IFS= read -r line; do
    	printf "Copying fastqc file: $line \n"
    
	    # SRA prefetch
	    cp $Original_Data_Folder/$line/00_fastqc_report/*_fastqc.zip $Project_Dir/Test_MultiQC/FastQC_data
	    printf "\n"
		done < $Project_Dir/SRA_Run_10_file.txt 
	
	# Copy data to slurm and delete slurm dir
	cp -r ${Project_Dir}/Test_run/01_MultiQC/FastQC_data/* ${ScratchDir}

	# MultiQC
	echo '\nIn scratch directory now: ' ;pwd
	printf "\n"

	# for repaired sample files
	multiqc fastqc_PRJEB29918/*_{1,2}_fastqc.zip --outdir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch/00_fastQC'

	mv multiqc_data multiqc_data_PRJEB29918
	mv multiqc_report.html multiqc_report_PRJEB29918.html
	mv fastqc_PRJEB29918 multiqc_data_PRJEB29918

	# for repaired sample files
	multiqc fastqc_PRJEB29918_repaired/*_final_{1,2}_fastqc.zip --outdir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch/00_fastQC'

	mv multiqc_data multiqc_data_PRJEB29918_repaired
	mv multiqc_report.html multiqc_report_PRJEB29918_repaired.html
	mv fastqc_PRJEB29918_repaired multiqc_data_PRJEB29918_repaired

	# for singleton files
	multiqc fastqc_PRJNA687506_repaired/*_singletons_fastqc.zip --outdir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch/00_fastQC'

	# Copy data back
	cp -r ${ScratchDir}/multiqc_data/* $Project_Dir/Test_run/01_MultiQC/MultiQC_data/
	cp -r ${ScratchDir}/multiqc_report.html $Project_Dir/Test_run/01_MultiQC/
	
	# remove the scratch directory
	cd $Project_Dir
	rm -rf ${ScratchDir}/

	# Deactivate env
	conda deactivate
printf '\n---------------------- End program ----------------------\n'
date
