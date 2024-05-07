
# Read data file
Data <- read.table('File_sizes.txt')
View(Data)

# Change colnames
colnames(Data) <- c('Size_KB', 'Sample_Name')

# Add a new column with size in MB
Data$Size_MB <- Data$Size_KB/1000

plot(seq(1:1736),sort(Data$Size_MB), type = 'b', pch = 18, col='steelblue', ylab = 'File Size in MB', xlab = 'Sample No.')


View(Data[order(Data$Size_MB, decreasing = T),])
