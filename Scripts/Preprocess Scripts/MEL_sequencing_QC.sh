# Script for a basic workflow to do QC of paired-end (PE) sequencing reads for microbiome wgs/amplicon samples. 
# 22/03/2024
# Tejus Shinde (MEL)


# Ideally it's just 5 cmds

	1. fastqc -t=2 ${R1_File} ${R2_File} -o ${OutDir} &
	2.  removehuman.sh in=${R1_File} outu=${R1_out} t=${CPUs_per_job}
	2.1 removehuman.sh in=${R1_File} outu=${R1_out} t=${CPUs_per_job}

	3. fastp --in1 ${R1_in_fastqName} --in2 ${R2_in_fastqName} --out1 ${R1_out_fastqName} --out2 ${R2_out_fastqName} --average_qual 20 --detect_adapter_for_pe --correction --overrepresentation_analysis --low_complexity_filter 

	4. bash ${BBMAP_dir}/repair.sh in1=${R1_in_fastqName} in2=${R2_in_fastqName} out1=${R1_out_fastqName} out2=${R2_in_fastqName} repair ignorebadquality=t tossbrokenreads=t overwrite=t -Xmx1G

# But for efficiency and multi sample analysis these cmds are optimised for our cluster and use. You always can update the parameters of course. 


# Add your variables here
	LogDir='' # add some path for the log files here

# Add your sample name and path here
	R1_File=''
	R2_File=''

# Add your output fastq name and path here
	R1_out=''
	R2_out=''

# Note 1 all the ${} are variables (that means they have values which you should specify). Check their values before running code. They should all be added to the script before running the cmd.
	# sanity checks can be done simply with 
		echo ${LogDir} # OR
		ls -hs ${LogDir}


# Step 1: Check quality of the sequencing reads
	# Activate fastqc env
	CondaDir='/home/data/galaxy_tool_dependencies/_conda/bin'
	source ${CondaDir}/activate __fastqc@0.11.9

	# run fastqc
	fastqc -t=2 ${R1_File} ${R2_File} -o ${OutDir} &

##-----------------####--------------####----------------##
##--------- Run the below cmds with the cluster (srun/sbatch) ---------##
##-----------------####--------------####----------------##

# Step 2: Decontamination i.e, remove human reads
	# Path for the BBTools script
	BBMAP_dir='/home/gpfs/o_shinde/Softwares_Tejus/bbmap'
	CPUs_per_job=6 # After some benchmarking this number of CPUs 6, seems ideal.
	LogDir='' # add some path here
	sample_ID='' # Give a sample name/identifier; Useful when you run multiple samples at once.

    # sanity check
    ls -hs ${R1_File} ${R2_File}

	# for read file 1
	bash ${BBMAP_dir}/removehuman.sh in=${R1_File} outu=${R1_out} t=${CPUs_per_job}

	# for read file 2
	bash ${BBMAP_dir}/removehuman.sh in=${R2_File} outu=${R2_out} t=${CPUs_per_job}

	# with cluster run these cmds would be
	'
	srun --partition=cpu --input none --cpus-per-task ${CPUs_per_job} --output=${LogDir}/FastQC_reads_output_${sample_ID}.out --error=${LogDir}/Err_fastqc_reads_${sample_ID}_job.err bash ${BBMAP_dir}/removehuman.sh in=${R1_File} outu=${R1_out} t=${CPUs_per_job}
	'

# Step 3: fastp does 4 things in 1 cmd: read quality filtering > adapter trimming > base quality correction > quality checks
	# Now we take the decontaminated reads (R1_out & R2_out) and further process them

	# specify paths here
		dataDir='' # Add the folder path to the data files here
		outDir= '' # Add the folder path where you want to save the output fastq files

	# new file names 
		sample_ID='xxx'
		R1_in_fastqName=${dataDir}/${sample_ID}'_R1.fastq.gz'  #for read 1 input file
		# OR use this if R2_out is the file you need
	    R1_in_fastqName=${R1_out}
	    R1_out_fastqName=${outDir}/${sample_ID}'_QC_R1.fastq.gz' # for read 1 output file

	    R2_in_fastqName=${dataDir}/${sample_ID}'_R2.fastq.gz' # for read 2 input file
	    R2_out_fastqName=${outDir}/${sample_ID}'_QC_R2.fastq.gz' # for read 2 output file
	    
    # fastp report vars
	    QC_report=${outDir}/Quality_stats/${sample_ID}'_fastp_QC_report.html'
	    QC_report_json=${outDir}/Quality_stats/${sample_ID}'_fastp_QC_report.json'
	    QC_report_title="${sample_ID} fastp QC report"

    # sanity check
    ls -hs ${R1_in_fastqName} ${R2_in_fastqName}

    # activate env
		MambaDir='/home/gpfs/o_shinde/Softwares_Tejus/conda_mamba/bin'
		source ${MambaDir}/activate fastp

    # the basic cmd is as follows
    	fastp --in1 ${R1_in_fastqName} --in2 ${R2_in_fastqName} --out1 ${R1_out_fastqName} --out2 ${R2_out_fastqName} --average_qual 20 --detect_adapter_for_pe --correction --overrepresentation_analysis --low_complexity_filter --thread 8 

    # with cluster run this cmds would be 
    '
    	srun --partition=cpu --input none --cpus-per-task ${threads_per_job} --mem 12GB --error=${LogDir}/"${sample_ID}_fastp_log.out" fastp --verbose --in1 ${R1_in_fastqName} --in2 ${R2_in_fastqName} --out1 ${R1_out_fastqName} --out2 ${R2_out_fastqName} --average_qual 20 --detect_adapter_for_pe --correction --overrepresentation_analysis --low_complexity_filter --thread 8 --html ${QC_report} --json ${QC_report_json} --report_title "${QC_report_title}"
    '

    # There should be an html file made with the QC report. Check these fastp reports for the detailed samplewise qc changes.

# step 4: Repair reads which have lost their mate :(
	# The QCed reads from fastp need to repaired now and then we're done!! :)

	# Path to the script
	BBMAP_dir='/home/gpfs/o_shinde/Softwares_Tejus/bbmap'

	# specify paths here
		dataDir='' # Add the folder path to the data files here
		outDir= '' # Add the folder path where you want to save the output fastq files

	# new file names 
		sample_ID='xxx'
		R1_in_fastqName=${dataDir}/${sample_ID}'_QC_R1.fastq.gz'  #for read 1 input file
	    R1_out_fastqName=${outDir}/${sample_ID}'_QC_repaired_R1.fastq.gz' # for read 1 output file

	    R2_in_fastqName=${dataDir}/${sample_ID}'_QC_R2.fastq.gz' # for read 2 input file
	    R2_out_fastqName=${outDir}/${sample_ID}'_QC_repaired_R2.fastq.gz' # for read 2 output file
	
	# sanity check
	ls -hs ${R1_in_fastqName} ${R2_in_fastqName}

	bash ${BBMAP_dir}/repair.sh --help

	# run repair script
	bash ${BBMAP_dir}/repair.sh in1=${R1_in_fastqName} in2=${R2_in_fastqName} out1=${R1_out_fastqName} out2=${R2_in_fastqName} repair ignorebadquality=t tossbrokenreads=t overwrite=t -Xmx1G

	# with cluster run this cmds would be # you can change the mem based on the file size(s)
	'
	srun --partition=cpu --input none --cpus-per-task 2 --mem 2GB --output=${LogDir}/Repair_reads_log/${ProjectID}_Repair_reads_output_${sample_ID}.out --error=${LogDir}/${ProjectID}_Err_Repair_reads_${sample_ID}_job.err bash ${BBMAP_dir}/repair.sh in1=${R1_file_name} in2=${R2_file_name} out1=${R1_out_name} out2=${R2_out_name} repair ignorebadquality=t tossbrokenreads=t overwrite=t -Xmx1G
	'

	# These reads are your final QC reads: ${R1_out_fastqName} & ${R2_out_fastqName}
	# You can do a fastqc again on them if you're interested to learn what was changed. 
	# Or you can check the fastp reports for the detailed samplewise qc changes


# step 5: Garbage cleanup i.e, delete all the intermediate fastq files from the decontam, fastp steps

