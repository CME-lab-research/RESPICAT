#!/bin/bash
#SBATCH --job-name=File_check_BioPro
#SBATCH --ntasks=8
##SBATCH --mem=4GB
#SBATCH --mail-user=tejus.shinde@medunigraz.at
#SBATCH --partition=debug
#SBATCH --cpus-per-task=1

# set all the variables
WorkDir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch'
cd ${WorkDir}
ProjectID='PRJNA687506'
Raw_Data_Folder=${WorkDir}/Backup_all_fastq_files
Batch_Data_Folder=${WorkDir}/Batch_Data/${ProjectID}
Date_Time=$(date +%d-%b-%H_%M)
loop_counter=1
printf "SampleID\tRaw_R1_count\tRaw_R2_count\tDecontaminated_R1_count\tDecontaminated_R2_count\tAvg_Raw_read_count\tAvg_decontam_read_count\n"
while IFS= read -r sample_ID; do
    if [[ $loop_counter -eq 1 ]]; then
    	printf "SampleID\tRaw_R1_count\tRaw_R2_count\tDecontaminated_R1_count\tDecontaminated_R2_count\tAvg.Raw_read_count\tAvg.decontam_read_count\n"
    	(( loop_counter++ ))
    fi
	Dr1c < $(($(zcat ${Batch_Data_Folder}/${sample_ID}"_decontam_1.fastq.gz"|wc -l)/4)) 
	Dr2c < $(($(zcat ${Batch_Data_Folder}/${sample_ID}"_decontam_2.fastq.gz"|wc -l)/4))
	Rr1c < $(($(zcat ${Raw_Data_Folder}/${sample_ID}"_1.fastq.gz"|wc -l)/4))
	Rr2c < $(($(zcat ${Raw_Data_Folder}/${sample_ID}"_2.fastq.gz"|wc -l)/4))

	# calculate avg read count for raw & decontaminated reads
	avg_raw_reads=$(((${Rr1c} + ${Rr2c})/2))
	avg_dc_reads=$(((${Dr1c} + ${Dr2c})/2))

	printf "${sample_ID}\t${Rr1c}\t${Rr2c}\t${Dr1c}\t${Dr2c}\t${avg_raw_reads}\t${avg_dc_reads}\n"
	done < ${WorkDir}/Final_SRA_IDs_grouped_lists/SRA_IDs_${ProjectID}_B1.txt > $WorkDir/Bioproject_data/${ProjectID}/Read_Counts_B1_${ProjectID}.txt.temp
printf ' \n---------------------- End program ----------------------\n '
date

sample_ID=SRR13336568