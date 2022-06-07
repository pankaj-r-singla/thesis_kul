# Code here.
library(gtools)#smartbind
library(car)#dataanalysis
library(tidyverse)
library(sjstats)#effectsize


setwd('D:\\EMG_Output_V5')
h_values = c(50,100,200,300,400,500)

for (h in h_values){
  data = read.table(file = paste('Ratings_',h,'_eng.tab',sep=''),head=T)
  data1 = read.table(file = paste('Ratings_',h,'_ned.tab',sep=''),head=T)
  alldata=smartbind(data,data1)
  
  alldata=rename(alldata,participant=V1,instructiontime=V2,block=V3,trail=V4,probability=V5,
                 intensity=V6,shock=V7,pleasantness=V8,unpleasantness=V9,
                 missing=V10,fEMG=V11)
  
  for (i in 1:2060){
    if (alldata$pleasantness[i]==9999){
      as.na(alldata$pleasantness[i])
    }
    if (alldata$unpleasantness[i]==9999){
      as.na(alldata$unpleasantness[i])
    }
    
  }
  outliers <- boxplot(fEMG ~ intensity*probability, alldata,plot=F)$out
  alldata<- alldata[-which(alldata$fEMG %in% outliers),]
  
  outliers <- boxplot(fEMG ~ intensity, alldata,plot=F)$out
  alldata<- alldata[-which(alldata$fEMG %in% outliers),]
  
  outliers <- boxplot(fEMG ~ probability, alldata,plot=F)$out
  alldata<- alldata[-which(alldata$fEMG %in% outliers),]
  
  
  
  model <- aov(fEMG~factor(block)*factor(probability)*factor(intensity)+Error(factor(participant)), data = alldata)
  summary(model)
  eta_sq(model)
  outputdir = paste('D:\\EMG_Output_plot_',h,'.pdf')
  pdf(file=outputdir)
  par(mfrow = c(2,2))
  
  alldata %>% 
    mutate(time = factor(block)) %>% 
    ggplot(aes(time, alldata$fEMG)) + geom_violin() + geom_jitter(alpha=.5,width=.1,height=0) 
  #+ coord_cartesian(xlim=c(0, 3), ylim=c(0, 0.15))
    labs(x="Block", y = "fEMG", 
         title=paste('fEMG over Block',h,'ms'), subtitle = "Violin Plots with (jittered) Observations")
  
  ggsave(paste('fEMG~block_',h,'.png',sep=''))
  
  alldata %>% 
    mutate(time = factor(probability,levels=c('0%','25%','50%','75%','100%'))) %>% 
    ggplot(aes(time, alldata$fEMG)) + geom_violin() + geom_jitter(alpha=.5,width=.1,height=0) + 
    labs(x="Probability", y = "fEMG", 
         title=paste('fEMG over Probability',h,'ms'), subtitle = "Violin Plots with (jittered) Observations")
  ggsave(paste('fEMG~probability_',h,'.png',sep=''))
  
  alldata %>% 
    mutate(time = factor(intensity)) %>% 
    ggplot(aes(time, alldata$fEMG)) + geom_violin() + geom_jitter(alpha=.5,width=.1,height=0) + 
    labs(x="Intensity", y = "fEMG", 
         title=paste('fEMG over Intensity',h,'ms'), subtitle = "Violin Plots with (jittered) Observations")
  ggsave(paste('fEMG~intensity_',h,'.png',sep=''))
  
  dev.off()
  
  png(paste('D:\\EMG_Output_V5\\fEMG~probability&intensity_',h,'.png',sep=''))
  
  alldata$probability = factor(alldata$probability, levels=c('0%','25%','50%','75%','100%'))
  boxplot(fEMG ~ probability:intensity,
          data = alldata,
          main = "fMEG~Probability&Intensity",
          xlab = "Block*Intensity",
          ylab = "fEMG",
          col = "steelblue",
          border = "black", 
          las = 2 #make x-axis labels perpendicular
  )
  
  dev.off()
