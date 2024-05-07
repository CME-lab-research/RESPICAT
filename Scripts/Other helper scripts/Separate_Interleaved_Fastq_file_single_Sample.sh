Data_Dir='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/01_Metaanalysis_Branch/Data/New_Data/SRA_Downloads'
Sample_ID='SRR1180013'

# add you file names
R1_file_name='${Sample_ID}_1.fastq.gz'
R2_file_name='${Sample_ID}_2.fastq.gz'

# cmd to repair
srun bash /home/gpfs/o_shinde/Softwares_Tejus/bbmap/repair.sh in=$Data_Dir/${Sample_ID}/${Sample_ID}.fastq.gz out1=$Data_Dir/${Sample_ID}/$R1_file_name out2=$Data_Dir/${Sample_ID}/$R2_file_name 


