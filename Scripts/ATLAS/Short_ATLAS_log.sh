# ATLAS executive log
# Written on: 12/10/2023
# Author: Tejus Shinde

# About: Log file to run ATLAS (metagenome-assembly pipeline) on MedBioNode. 
# Useful resources to read: 
	# Expected output from ATLAS: "https://metagenome-atlas.readthedocs.io/en/latest/"
	# Errors, versions and functionalities check GitHub: 'https://github.com/metagenome-atlas/atlas'

# P.S. Before running ATLAS on your own data
#	1. You can also run ATLAS on demo data provided by ATLAS and get familiar to pipeline. (It runs in a couple of days max (2 samples only)) OR
#	2. You can read the documentation (expecially the expected output sections is imp) on the above pages. 
# This log is assumes that you have set your cluster profile. It's a short step explained in the ATLAS SOP on medbox. Or you can do it from here: 'https://metagenome-atlas.readthedocs.io/en/latest/usage/getting_started.html#set-up-of-cluster-execution'

# Encouragement: You can do it. It's not that overwhelming. All the ATLAS output files are stored in a logical manner. It helps to debug errors later. 

# Let's start now:

# Keep the terminal 'ON' all the time with this cmd. 
screen -S ‘ATLAS_run’
	# When you leave press Ctrl+A+D to exit screen session
	# Reconnect to the screen session with screen -r 'Screen_session_Name'
		# you can find the screen session name with: screen -ls

## Where is your data? Move all the fastq.gz files to a folder and add the path here
dataDir=home/cluster/o_xxx/Reads

# Create a working dir (for ATLAS output files) and navigate into that folder
ProjectDir='/home/gpfs/o_xxx/Project_Name/01_ATLAS_run' # add the working dir path here. It will create a folder below
dbDir='/home/conda/int_microbiome/databases/atlas'
CondaDir='/home/conda/miniconda3/bin'
LogDir=${ProjectDir}/Personal_Logs
N_JOBS=12 # 12 usually works fine. If the cluster is super busy then you can also reduce it to 8 or 6

# create relevant folders
mkdir ${ProjectDir};  mkdir ${LogDir}

## sanity check # question for you: Are the paths correct?
ls -hs ${dbDir} ${dataDir}

# go to ATLAS directory
cd ${ProjectDir}

# Activate the conda env for ATLAS
source ${CondaDir}/activate atlas_2.18.0

# sanity check
atlas --version
	# should give you an output like this: atlas, version 2.18.0

# Initializing ATLAS in your project dir
atlas init ${dataDir} --db-dir ${dbDir} --working-dir ${ProjectDir} --assembler megahit --data-type metagenome 

	# After this step 2 files are created. "samples.tsv" & "config.yaml"

	# Add metadata to this samples.tsv file
	# Edit the config file according to your preferances or you can use the info from the ATLAS run SOP on medbox
		# imp thing is to add the Human genome to the contamination removal section (contaminant_references:)
		# Remove VAMB & SemiBin comment only if you want to do co-binning. See [https://github.com/metagenome-atlas/atlas/discussions/441#discussioncomment-2611117]
			# If you do want co-binning add a 'BinGroup' column to your samples.tsv file

# After editing the config.yaml file and samples.tsv file, you can start running ATLAS
	# run QC: 
		# Dry run
		sbatch --job-name='ATLAS_QC' -o ${LogDir}/ATLAS_job_log.tmp -e ${LogDir}/ATLAS_job_err_log.tmp atlas run qc --profile cluster --jobs 8 --keep-going --dry-run

		# Check the ${LogDir}/ATLAS_job_log.tmp & ${LogDir}/ATLAS_job_err_log.tmp file. If there are no errors then do the actual run

		# Actual run 
		sbatch --job-name='ATLAS_QC' -o ${LogDir}/ATLAS_QC.out -e ${LogDir}/ATLAS_QC.err atlas run qc --profile cluster --jobs ${N_JOBS} --keep-going --latency-wait 2000
		# check log again to see if everything has run properly. If YES then continue. If NO then check the Debug tips below.

	# run assembly
		# Dry run
		sbatch --job-name='ATLAS_assemble' -o ${LogDir}/ATLAS_assemble.out.tmp -e ${LogDir}/ATLAS_assemble.err.tmp atlas run assembly --profile cluster --jobs ${N_JOBS} --keep-going --dry-run
		# Check the ${LogDir}/ATLAS_job_log.tmp & ${LogDir}/ATLAS_job_err_log.tmp file. If there are no errors then do the actual run

		# Actual run
		sbatch --job-name='ATLAS_assemble' -o ${LogDir}/ATLAS_assemble.out -e ${LogDir}/ATLAS_assemble.err atlas run assembly --profile cluster --jobs ${N_JOBS} --keep-going --latency-wait 30000
		# check log again to see if everything has run properly. If YES then continue. If NO then check the Debug tips below.
		
	# run binning
		# Dry run
		sbatch --job-name='ATLAS_Bin' -o ${LogDir}/ATLAS_Binning.out.tmp -e ${LogDir}/ATLAS_Binning.err.tmp atlas run binning --profile cluster --jobs ${N_JOBS} --keep-going --dry-run	
		# Check the ${LogDir} files. If there are no errors then do the actual run

		# Actual run
		sbatch --job-name='ATLAS_Bin' -o ${LogDir}/ATLAS_Binning.out -e ${LogDir}/ATLAS_Binning.err atlas run binning --profile cluster --jobs ${N_JOBS} --keep-going --latency-wait 30000
		# check log again to see if everything has run properly. If YES then continue. If NO then check the Debug tips below.

	# run genomes
		# Dry run
		sbatch --job-name='ATLAS_Genomes' -o ${LogDir}/ATLAS_Genomes.out -e ${LogDir}/ATLAS_Genomes.err atlas run genomes --profile cluster --jobs ${N_JOBS} --keep-going --dry-run	
		# Check the ${LogDir} files. If there are no errors then do the actual run

		# Actual run
		sbatch --job-name='ATLAS_Genomes' -o ${LogDir}/ATLAS_Genomes.out -e ${LogDir}/ATLAS_Genomes.err atlas run genomes --profile cluster --jobs ${N_JOBS} --keep-going --latency-wait 30000
		# check log again to see if everything has run properly. If YES then continue. If NO then check the Debug tips below.

	# Optional GENE catalog
		# Dry run
		sbatch --job-name='ATLAS_GC' -o ${LogDir}/ATLAS_GeneCat.out -e ${LogDir}/ATLAS_GeneCat.err atlas run genecatalog --profile cluster --jobs ${N_JOBS} --keep-going --dry-run	
		# Check the ${LogDir} files. If there are no errors then do the actual run

		# Actual run
		sbatch --job-name='ATLAS_GC' -o ${LogDir}/ATLAS_GeneCat.out -e ${LogDir}/ATLAS_GeneCat.err atlas run genecatalog --profile cluster --jobs ${N_JOBS} --keep-going --latency-wait 30000

# Some tips for debugging:
#	We are running code with slurm to make it faster and so that we can capture the error and output logs more efficiently. Do not run the next step before checking the log and resolving the errors (if any). If each step of ATLAS is successfully run then there are files created in the "reports"/ folder. This is a sign to run the next step.

# 1. Check the most recent log file created to see if there are any errors or not. 
# 2. The quickest way to look for an error is to 
#		a. Open the log file in any text editor & search for the word 'Error in rule'
#			Many times it's the same error repeating for multiple files. (Good news for us)
#		b. Read the log file for that specific rule (It is given in that section 'Error in rule')
#		c. When asking for help send the overall log file (eg. ${LogDir}/ATLAS_Genomes.out &  ATLAS_Genomes.err) with the rule specific log files.
#		d. You can also search the errors in the github repository (link provided above) & read the discussion/issues section and find the answer.
# 		e. Most of the errros are arising because some samples don't have enough reads/assemblies/bins. Thus, you may have to exclude some samples at every step. i.e, remove sample ID rows from your samples.tsv file. 
# 		f. If you couldn't fix the error even after all this gimmicks, then contact Tejus at 'tejus.shinde@medunigraz.at'

# Yours sincerely,
# Tejus Shinde
