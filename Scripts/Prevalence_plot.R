library(ggplot2)
library(tidyverse)

# plot prevalence of viral and fungal taxa

# read prevalence file
prevDf<- read.table("Prevalence_Viral_fungal.txt", header = T, stringsAsFactors = T, check.names = T, sep='\t')

# set up cut-off values 
breaks <- c(0,10,100,250,500,750,1000, 10000)
# specify interval/bin labels
tags <- c("[0-10)", "[10-100)", "[100-250)","[250-500)", "[500-750)","[750-1000)", "[1000-10000)")

# bucketing values into bins
group_tags <- cut(prevDf$Number.of.fragments_Fungi, 
                  breaks=breaks, 
                  include.lowest=TRUE, 
                  right=FALSE, 
                  labels=tags)
# inspect bins
summary(group_tags)

# plot the bins
ggplot(data = as_tibble(group_tags), mapping = aes(x=value)) + 
  geom_bar(fill="bisque",color="white",alpha=0.7) + 
  stat_count(geom="text", aes(label=sprintf("%.2f",..count..*100/length(group_tags))), vjust=-0.5) +
  labs(x='Bins of #reads mapped', title = 'PRJNA671740 Prevalence and distribution of braken fungal (K) taxa') +
  theme_minimal() 

# Viral taxa distribution
# bucketing values into bins
group_tags <- cut(prevDf$Number.of.fragments_Virus, 
                  breaks=breaks, 
                  include.lowest=TRUE, 
                  right=FALSE, 
                  labels=tags)
# inspect bins
summary(group_tags)

# plot the bins
ggplot(data = as_tibble(group_tags), mapping = aes(x=value)) + 
  geom_bar(fill="bisque",color="white",alpha=0.7) + 
  stat_count(geom="text", aes(label=sprintf("%.4f",..count..*100/length(group_tags))), vjust=-0.5) +
  labs(x='Bins of #reads mapped', title = 'PRJNA671740 Prevalence and distribution of braken viral (D) taxa') +
  theme_minimal() 

