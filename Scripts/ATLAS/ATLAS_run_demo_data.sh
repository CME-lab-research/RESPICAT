# Variables
	Date_Time=$(date +%d-%b-%H_%M)
	ProjectID='ATLAS_pilot'
	workDir='/home/gpfs/o_shinde/Slurm_Job_Space/demo_MAG_assembly_runs/ATLAS_run'
	DataDir="/home/gpfs/o_shinde/Slurm_Job_Space/demo_MAG_assembly_runs/test_reads"
	# Create a working dir and navigate into that folder
	dbDir='/home/gpfs/o_shinde/References_local/ATLAS_ref'
	Project_Dir=$workDir

# Activate the conda env for ATLAS
source /home/gpfs/o_shinde/Softwares_Tejus/conda_mamba/bin/activate atlas_v2.17.2

# Applying atlas to your data OR Initializing ATLAS in your project dir
atlas init --db-dir $dbDir --working-dir $Project_Dir --assembler megahit $Project_Dir/Raw_data/ --data-type metagenome

# cp and edit the config.yaml file and samples.tsv file 
	cp config.yaml samples.tsv $workDir/03_ATLAS/PRJNA382701_SE/
	# edit the config file and cp back
	cp $workDir/03_ATLAS/PRJNA382701_SE/config.yaml $workDir/03_ATLAS/PRJNA382701_SE/samples.tsv ./

	# run QC: 
		# Dry run
		srun --job-name='ATLAS_pilot' atlas run qc --jobs 46 --keep-going --dry-run
		Date_Time=$(date +%d-%b-%H_%M)
		atlas run qc --profile cluster --jobs 46 --keep-going --report QC_report_${Date_Time}.html

		# Actual run 
		atlas run qc --profile cluster --jobs 46 --keep-going --latency-wait 360

	# run assembly
		# Dry run
		srun atlas run assembly --profile cluster --jobs 46 --keep-going --dry-run
		Date_Time=$(date +%d-%b-%H_%M)
		atlas run assembly --profile cluster --jobs 46 --keep-going --dry-run --report Assembly_report_${Date_Time}.html

		# Actual run
		atlas run assembly --profile cluster --latency-wait 360 --jobs 46 --keep-going
		
	# run binning
		# Dry run
		srun atlas run binning --profile cluster --jobs 46 --keep-going --dry-run --latency-wait 360 	

		# Actual run
		srun atlas run binning --profile cluster --latency-wait 360 --jobs 12 --keep-going


# Deviation
atlas run genecatalog --jobs 46 --keep-going --dry-run