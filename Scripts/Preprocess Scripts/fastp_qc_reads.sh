#!/bin/bash
printf '\n---------------------- Start program ----------------------\n'
pwd; date
# program to do read qc. quality filtering > adapter trimming > base quality correction

# Enter project ID 
  ProjectID='UniBergen'
  
  screen_sessionName="Fastp_${ProjectID}"
# screen -S "${screen_sessionName}"

  # sanity check
  screen -ls

# vars
  WorkDir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch'; cd ${WorkDir}
  MambaDir='/home/gpfs/o_shinde/Softwares_Tejus/conda_mamba/bin'
  outDir=${WorkDir}/Batch_Data/${ProjectID}'_QC'; mkdir -vp ${outDir}; mkdir -vp ${outDir}/Quality_stats
  #dataDir=${WorkDir}/Batch_Data/${ProjectID}'_repaired'
  dataDir=${WorkDir}/Backup_all_fastq_files
  LogDir=${WorkDir}/Logs/02_fastp_qc
  Date_Time=`date +%d-%b_%H:%M`
  threads_per_job=6
  counter=1

# sanity check
  ls -hs ${dataDir}; du -hs ${dataDir}; ls -hs ${dataDir} | wc -l 

# activate env
  source ${MambaDir}/activate fastp

# actual run
while IFS= read -r sample_ID; do
    printf "\n --------------------- Starting QC of reads for: ${sample_ID} --------------------- \n"
    # specify read filenames
      # read 1 file
    R1_in_fastqName=${dataDir}/${sample_ID}'_R1_001.fastq.gz'
    R1_out_fastqName=${outDir}/${sample_ID}'_QC_1.fastq.gz'
      # read 2 file
    R2_in_fastqName=${dataDir}/${sample_ID}'_R2_001.fastq.gz'
    R2_out_fastqName=${outDir}/${sample_ID}'_QC_2.fastq.gz'
      # fastp report vars
    QC_report=${outDir}/Quality_stats/${sample_ID}'_fastp_QC_report.html'
    QC_report_json=${outDir}/Quality_stats/${sample_ID}'_fastp_QC_report.json'
    QC_report_title="${ProjectID} - ${sample_ID} fastp QC report"

    # sanity check
    ls -hs ${R1_in_fastqName} ${R2_in_fastqName}

    # run fastp on server
    srun --partition=cpu --input none --cpus-per-task ${threads_per_job} --mem 12GB --error=${LogDir}/"${ProjectID}_${sample_ID}_fastp_log.out" --job-name='Speedy_'${sample_ID} fastp --verbose --in1 ${R1_in_fastqName} --in2 ${R2_in_fastqName} --out1 ${R1_out_fastqName} --out2 ${R2_out_fastqName} --average_qual 20 --detect_adapter_for_pe --correction --overrepresentation_analysis --low_complexity_filter --thread 8 --html ${QC_report} --json ${QC_report_json} --report_title "${QC_report_title}" &

    # counter to pause the srun after n number of srun cmds.
    if (( ${counter} % 50 == 0 )); then
      #printf 'In loop; Taking a break\n'
      sleep 600
      #printf 'Done waiting'
    fihy  
    let counter++
    printf " \n --------------------- Ending QC of reads ------------------------- \n "
    done < ${WorkDir}/Final_SRA_IDs_grouped_lists/SRA_IDs_${ProjectID}.txt > ${WorkDir}/Bioproject_data/${ProjectID}/fastp_QC_reads_${ProjectID}.out
  
  echo ${Date_Time}
  printf ' \n---------------------- End program ----------------------\n '

  # deactivate env
  source ${MambaDir}/activate
