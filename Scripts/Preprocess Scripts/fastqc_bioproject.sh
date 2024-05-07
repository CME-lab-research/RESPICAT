#!/bin/bash 

# Add Project ID here 
  ProjectID='PRJNA687506'
  File_ID=${ProjectID}'_repaired' # (also repaired)
  counter=1

# Initializing variables and setting up the environment
Project_Dir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch'
LogDir=${Project_Dir}/Logs/00_fastqc_logs
#dataDir=${Project_Dir}/Backup_all_fastq_files
dataDir=${Project_Dir}/Batch_Data/${File_ID} #; ls -hs ${dataDir}
OutDir=${Project_Dir}/00_fastQC/multiqc_data_${File_ID}/fastqc_${File_ID}
Date_Time=$(date +%d-%b_%H:%M)

# Activate fastqc env
CondaDir='/home/data/galaxy_tool_dependencies/_conda/bin'
source ${CondaDir}/activate __fastqc@0.11.9

# Run fastqc
while IFS= read -r sample_ID; do
	printf "Fastqc file: $sample_ID \n"
	# get read filenames
	R1_File=$(ls ${dataDir}/${sample_ID}_*1.fastq.gz)
	R2_File=$(ls ${dataDir}/${sample_ID}_*2.fastq.gz)
	#R3_File=$(ls ${dataDir}/${sample_ID}_singletons.fastq.gz)

	# fastqc
	#srun --partition=cpu --input none --cpus-per-task 2 --mem 18GB --output=${LogDir}/${File_ID}_FastQC_reads_output_${sample_ID}.out --error=${LogDir}/${File_ID}_Err_fastqc_reads_${sample_ID}_job.err --job-name='R2D2_'${sample_ID} fastqc -t=2 ${R1_File} ${R2_File} -o ${OutDir} & # ${R3_File}
	printf "\n"

    # counter to pause the srun after n number of srun cmds.
    if (( ${counter} % 12 == 0 )); then
      #printf 'In loop; Taking a break\n'
      sleep 0.003
      #printf 'Done waiting'
    fi
    let counter++
	done < ${Project_Dir}/Final_SRA_IDs_grouped_lists/SRA_IDs_${ProjectID}.txt > ${LogDir}/Fast_QC_${File_ID}.out
	
# change env
	conda deactivate

wait

printf '\n---------------------- End program ----------------------\n'
date