#Author: Emily Kibbler

#install.packages("tidyverse")
#install.packages("readxl")
#install.packages("Bioconductor")
BiocManager::install("biomaRt")
library(tidyverse)
library(readxl)
library(biomaRt)


all_data<-read_xlsx("GSE224615_DEGs.xlsx")


most_changed<-all_data
most_changed$abs_change<-abs(most_changed$log2FoldChange)
most_changed<-most_changed[order(most_changed$abs_change,decreasing = TRUE),]
most_changed<-most_changed[1:250,] #subset on the top 250 most changed in either direction

#top 10 downregulated, top 10 upregulated
most_changed<-all_data
most_changed<-all_data[order(all_data$log2FoldChange),][1:10,] #most downregulated genes
most_changed<-rbind(most_changed,all_data[order(all_data$log2FoldChange, decreasing=TRUE),][1:10,])
most_changed<-most_changed[,c(1:4,41)]

view(most_changed)

#subset on fc more than 1
fc_more_than_one<-subset(most_changed,most_changed$abs_change>1)
#write.csv(fc_more_than_one,"fc_more_than_one.csv",row.names=FALSE)

ensembl = useEnsembl(biomart="ensembl", dataset="hsapiens_gene_ensembl")
listFilters(ensembl)
mart=ensembl
#useMart(ensembl)

attributes_df<-as.data.frame(listAttributes(ensembl)) #what you want to retrieve
filters_df<-listFilters(ensembl) #how you want to find it

#find the correct keyword for what I want
view(subset(attributes_df,grepl("go",attributes_df$description,fixed=FALSE,ignore.case=TRUE)==TRUE))
view(subset(filters_df,grepl("ensembl",filters_df$name,fixed=FALSE,ignore.case=TRUE)==TRUE))


#head(getBM(attributes=c('go_id','definition_1006','description','external_gene_name'),filters=	'ensembl_gene_id',most_changed$ID,mart=ensembl))

go_results<-getBM(attributes=c('goslim_goa_description','external_gene_name'),filters=	'ensembl_gene_id',most_changed$ID,mart=ensembl)

#go_results<-getBM(attributes=c('go_id','definition_1006','description','external_gene_name'),filters=	'ensembl_gene_id',most_changed$ID,mart=ensembl)

terms<-unique(go_results$goslim_goa_description)
summary<-data.frame(matrix(ncol=2,nrow=length(terms)))
colnames(summary)<-c("Term","Frequency")

for(i in 1:length(terms)){
  temp<-subset(go_results,go_results$goslim_goa_description==terms[i])
  summary$Term[i]<-terms[i]
  summary$Frequency[i]<-nrow(temp)
}


summary(summary$Frequency)

nrow(subset(summary,summary$Frequency>10)) #top 38 GO descriptions

subset(summary,summary$Frequency>10) %>% ggplot(aes(x=Term,y=Frequency))+
  geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=45,hjust=1))

go_results<-getBM(attributes=c('go_id','definition_1006','description','external_gene_name'),filters=	'ensembl_gene_id',most_changed$ID,mart=ensembl)

