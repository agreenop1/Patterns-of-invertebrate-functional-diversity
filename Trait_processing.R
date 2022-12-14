# author Arran Greenop

rm(list = ls())

#packages
library(ade4)
library(FD)
library(reshape2)

# function to compile occupancy estimates into an array #################################################################### 
# x = list of occupancy estimates and reg = region (one of England, Scotland, Wales, Northern_Ireland, UK or GB)

sp_arr<-function(x,reg){
  #subset occupancy records for correct species
  sp_occ_m <- subset(melt(x, id=1:4), Region==reg, select=c("Group","Species","Iteration","variable","value"))
  sp_occ_m$year <- as.numeric(gsub(patt="X", repl="", x=sp_occ_m$variable))
  sp_occ_m$Species <- as.character(sp_occ_m$Species) # means that j_post ends up in alphabetical order
  #array
  j_post <- acast(sp_occ_m, Species~Iteration~year)
  return(j_post)
}

# function to put occupancy into a list for diversity measures ####################################################

occ.list <- function(x){
  L<-list()
  for (i in 1:1000){
    
    L[[i]]<-x[,i,]
  }
  L
}

############################################POLLINATORS############################################################
#traits
POLL_Et<-read.csv("POLL_ET.csv",header=T,row.names = 1)
POLL_Et<-POLL_Et[order(rownames(POLL_Et)),]

#remove trait resolution column
POLL_Et$Trait_resolution<-NULL

#carry out PCoA
Pollet  <-dudi.pco(gowdis(POLL_Et),scannf = FALSE, nf = 4)

#summary of axes
summary(Pollet)
Pollet<-Pollet$li #select axes

saveRDS(Pollet,"Poll_pco_et.rds")

#list for species occupancy
POLL_occ<-readRDS("POLL_OCC.rds")

#reorder dataframe alphabetically
POLL_ALL <-sp_arr(POLL_occ,reg="GB")

#occupancy as a list for jasmin
POLL_L <-occ.list(POLL_ALL)

saveRDS(POLL_L,"POLL_L.rds")

##########################################AQUATIC FUNCTIONS############################################################
#traits
AQUA_Et<-read.csv("AQUA_ET.csv",header=T,row.names = 1)

#remove trait resolution column
AQUA_Et$Trait_resolution<-NULL

#reorder dataframe alphabetically
AQUA_Et<-AQUA_Et[order(rownames(AQUA_Et)),]

#convert to proportions 
AQUA_Et<-prep.fuzzy.var(AQUA_Et,c(5,6,8,7))


#for overall diversity metrics - using mixed variable distance coefficient
#F relates to fuzzy coding
AQUA_Et1<-dist.ktab(ktab.list.df(list(AQUA_Et)), type = c("F"),option = c("noscale"))

#carry out PCoA
Aquaet <-dudi.pco(AQUA_Et1, scannf = FALSE, nf = 5)

#summary of axes
summary(Aquaet)
Aquaet <-Aquaet$li
saveRDS(Aquaet ,"Aqua_pco_et.rds")

#list for species occupancy
AQUA_occ<-readRDS("AQUA_OCC.rds")

#reorder dataframe alphabetically
AQUA_ALL <-sp_arr(AQUA_occ,reg="GB")

#occupancy as a list for jasmin
AQUA_L <-occ.list(AQUA_ALL)
saveRDS(AQUA_L,"AQUA_L.rds")

##########################################PEST CONTROL###############################################################
#traits
PECO_Et<-read.csv("PECO_ET.csv",header=T,row.names = 1)
PECO_Et<-PECO_Et[order(rownames(PECO_Et)),]

#carry out PCoA
Pecoet <-dudi.pco(gowdis(PECO_Et),scannf = FALSE,  nf = 3)

#summary of axes
summary(Pecoet)
Pecoet <-Pecoet$li
saveRDS(Pecoet ,"Peco_pco_et.rds")

#list for species occupancy
PECO_occ<-readRDS("PECO_OCC.rds")

#reorder dataframe alphabetically
PECO_ALL <-sp_arr(PECO_occ,reg="GB")

#occupancy as a list for jasmin
PECO_L <-occ.list(PECO_ALL)

saveRDS(PECO_L,"PECO_L.rds")

############################################PESTS###########################################################################
#trait
PEST_Et<-read.csv("PEST_ET.csv",header=T,row.names = 1)
PEST_Et<-PEST_Et[order(rownames(PEST_Et)),]

#carry out PCoA
Pestet <-dudi.pco(gowdis(PEST_Et),scannf = F, nf = 3)

#summary of axes
summary(Pestet)
Pestet <-Pestet$li
saveRDS(Pestet ,"Pest_pco_et.rds")

#list for species occupancy
PEST_occ<-readRDS("PEST_OCC.rds")

#reorder dataframe alphabetically
PEST_ALL <-sp_arr(PEST_occ,reg="GB")

#occupancy as a list for jasmin
PEST_L <-occ.list(PEST_ALL)

saveRDS(PEST_L,"PEST_L.rds")
