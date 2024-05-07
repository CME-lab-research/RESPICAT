prefetch ERR3832239  -O SRA_Downloads

	'	2022-04-05T09:27:22 prefetch.3.0.0:  HTTPS download succeed
		2022-04-05T09:27:22 prefetch.3.0.0:   verifying 'ERR4853138'...
		2022-04-05T09:27:24 prefetch.3.0.0:  'ERR4853138' is valid
		2022-04-05T09:27:24 prefetch.3.0.0: 1) 'ERR4853138' was downloaded successfully
		2022-04-05T09:27:24 prefetch.3.0.0: 'ERR4853138' has 0 unresolved dependencies
		'
fasterq-dump ERR4853138

ps aux | grep gzip

SRA_Data_Folder='/home/cluster/o_shinde/Projects/Work/P1_Catalog_Project/Data/SRA_Downloads/'

'Original echo $PATH: /usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
	export PATH=$PATH:/home/cluster/o_shinde/Softwares/sratoolkit.3.0.0-ubuntu64/bin/
'
prefetch SRR642751  -O $SRA_Data_Folder
fasterq-dump ERR4853138 -O $SRA_Data_Folder/ERR4853138/
gzip $SRA_Data_Folder/ERR4853138/*.fastq
du -ah $SRA_Data_Folder/

strings=(
	SRR1927265
	SRR2842672
	SRR3099549
	SRR642626
	SRR642627
	SRR642628
	SRR642629
	SRR642631
	SRR642633
	SRR642634
	SRR642635
	SRR642636
	SRR642637
	SRR642638
	SRR642639
	SRR642640
	SRR642641
	SRR642642
	SRR642643
	SRR642644
	SRR642645
	SRR642646
	SRR642647
	SRR642648
	SRR642649
	SRR642650
	SRR642683
	SRR642719
	SRR642746
	SRR642747
	SRR642748
	SRR642749
	SRR642750
	)

array=( string{--help -V} )

for i in "${array[@]}"; do
    echo "$i"
done

for i in "${strings[@]}"; do
	ls $SRA_Data_Folder/$i
	echo "---------------------------------------- $i"
done