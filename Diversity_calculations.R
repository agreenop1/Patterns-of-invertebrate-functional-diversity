# author Arran Greenop

rm(list = ls()) 
library(BAT)
library(hypervolume)



# this code is largely replicated from BAT package functions but allows seed to be set in loops

# create a list of hypervolumes #####################################################################################
# this is used in the kernel alpha function

list.hypervolumes.a = function(comm, trait, method = method, abund = FALSE, ... ) {
  
  #check for missing data
  if (ncol(comm) != nrow(trait))
    stop("Number of species in comm and trait matrices are different")
  if (any(is.na(comm)) || any(is.na(trait)))
    stop("The function cannot be computed with missing values. Please remove observations with missing values.")
  
  #convert data if needed
  if (class(comm) == "data.frame")
    comm <- as.matrix(comm)
  if(class(trait) == "data.frame")
    trait = as.matrix(trait)
  
  #rename species in comm and trait if species names are missing
  if(is.null(colnames(comm)))
    colnames(comm) = paste(rep("Sp",ncol(comm)),1:ncol(comm),sep='')
  if(is.null(rownames(trait)))
    rownames(trait) = paste(rep("Sp",nrow(trait)),1:nrow(trait),sep='')
  
  #check if there are communities with no species
  comm2 = comm[rowSums(comm) > 0,]
  if(nrow(comm2) != nrow(comm))
    warning(paste("In the site x species matrix (comm), one or more rows contain no species.\n  These rows have been removed prior to hypervolume estimation.")) 
  comm <- comm2
  nComm <- nrow(comm)
  
  subComm <- comm[1,] ## Selecting the first community
  subTrait <- trait[comm[1,]>0,] ## Selecting trait values of the community
  subComm <- subTrait[rep(1:nrow(subTrait), times = subComm[comm[1,]>0]), ] ## Replicating each trait combination times the abundance of each species
  
  #build hypervolumes
  for (s in 1:nComm) {
    set.seed(1)#ensure hypervolumes are comparable
    if(abund){
      subComm <- comm[s,] ## Selecting the community
      subTrait <- trait[comm[s,]>0,] ## Selecting trait values of the community
      subComm <- subTrait[rep(1:nrow(subTrait), times = subComm[comm[s,]>0]), ] ## Replicating each trait combination times the abundance of each species
    } else {
      subComm <- trait[comm[s,]>0,]
    }
    
    if (method == "box")
      newHv <- (hypervolume_box(subComm,verbose=FALSE, ...))
    else if (method == "svm")
      newHv <- (hypervolume_svm(subComm,verbose=FALSE, ...))
    else if (method == "gaussian")
      newHv <- (hypervolume_gaussian(subComm,verbose=FALSE, ...))
    else
      stop(sprintf("Method %s not recognized.", method))
    if(s == 1){
      hv = newHv
      cat(paste("Hypervolume ",as.character(s)," out of ",as.character(nComm)," has been constructed.",sep=''))
    }
    else{
      hv <- hypervolume_join(hv,newHv)
      cat(paste("\nHypervolume ",as.character(s)," out of ",as.character(nComm)," has been constructed.",sep=''))
    }
  }
  
  #add names to hypervolume list
  if(!is.null(rownames(comm))){
    for (j in 1:length(hv@HVList))
      hv@HVList[[j]]@Name <- rownames(comm)[j]
    message("\nHypervolumes have been named with rownames of the site x species matrix")
  }	else {
    hv = name.hypervolumes(hv)
  }
  
  return(hv)
}

# name list of hypervolumes #############################################################################
name.hypervolumes = function(hvlist){
  missingName = FALSE
  for (j in 1:length(hvlist@HVList)){
    if(hvlist@HVList[[j]]@Name == "untitled"){
      hvlist@HVList[[j]]@Name = paste("HV_",as.character(j),sep='')
      missingName = TRUE
    }
  }
  if(missingName)
    print("Hypervolumes lacking a name have been named according to their position in the HypervolumeList.")
  
  return(hvlist)
}




# hypervolume calculation #################################################################################
# community and trait data
kernel.alpha.a <- function(comm, trait, method = "gaussian", abund = TRUE, return.hv = TRUE, ...){
  
  #check if right data is provided
  if (!(class(comm) %in% c("HypervolumeList", "Hypervolume", "data.frame", "matrix")))
    stop("A Hypervolume, a HypervolumeList, or a sites x species matrix or data.frame is needed as input data.")
  
  #convert data if needed
  if (class(comm) == "Hypervolume")
    return(get_volume(comm))
  else if (class(comm) == "HypervolumeList")
    hvlist <- name.hypervolumes(comm) 	#name hypervolumes if needed
  else
    hvlist <- list.hypervolumes.a(comm = comm, trait = trait, method = method, abund = abund, ...)
  
  #calculate alpha values and give them a name
  alphaValues <- c()
  for (i in 1:length(hvlist@HVList)){
    alphaValues <- append(alphaValues, get_volume(hvlist@HVList[[i]]))
    names(alphaValues[[i]]) <- hvlist@HVList[[i]]@Name
  }
  
  #return alpha values
  if(return.hv)
    return(list(alphaValues, hvlist))
  else
    return(alphaValues)
}


# calculates similarity measures ###########################################################################
# can use community and trait data or list of hypervolumes
kernel.beta.a = function(comm, trait, method = "gaussian", func = "jaccard", abund = FALSE, return.hv = FALSE, ... ){
  
  #check if right data is provided
  if (!(class(comm) %in% c("HypervolumeList", "data.frame", "matrix")))
    stop("A HypervolumeList, or a sites x species matrix or data.frame is needed as input data.")
  
  #convert data if needed
  if (class(comm) == "HypervolumeList")
    hvlist <- name.hypervolumes(comm) 	#name hypervolumes if needed
  else
    hvlist <- list.hypervolumes.a(comm = comm, trait = trait, method = method, abund = abund, ...)
  
  #create matrices to store results
  nComm <- length(hvlist@HVList)
  Btotal <- matrix(NA, nrow = nComm, ncol = nComm)
  Brepl  <- matrix(NA, nrow = nComm, ncol = nComm)
  Bdiff  <- matrix(NA, nrow = nComm, ncol = nComm)
  
  #calculate beta values and give them a name
  hvNames <- c()
  for (i in 1:nComm){
    hyper <- hvlist@HVList[[i]]
    for(j in i:nComm){
      hyper2 <- hvlist@HVList[[j]]
      set.seed(1)
      hyperSet <- hypervolume_set(hyper, hyper2, check.memory=FALSE,verbose=FALSE, num.points.max = 100000)#increased points to 100000
      union    <- hyperSet[[4]]@Volume
      unique1  <- hyperSet[[5]]@Volume
      unique2  <- hyperSet[[6]]@Volume
      if(tolower(substr(func, 1, 1)) == "s")
        union <- 2 * union - unique1 - unique2
      Btotal[j,i] <- (unique1 + unique2) / union
      Brepl[j,i]  <- 2 * min(unique1, unique2) / union 
      Bdiff[j,i]  <- abs(unique1 - unique2) / union 
    }
    hvNames[i] <- hvlist@HVList[[i]]@Name
    message(paste("Pairwise beta diversity of the hypervolume ",as.character(i)," out of ",as.character(nComm)," have been calculated.\n",sep=''))
  }
  
  #tidy up things
  rownames(Btotal) <- colnames(Btotal) <- rownames(Brepl) <- colnames(Brepl) <- rownames(Bdiff) <- colnames(Bdiff) <- hvNames
  betaValues <- list(Btotal = as.dist(Btotal), Brepl = as.dist(Brepl), Bdiff = as.dist(Bdiff))
  
  #return beta values
  if(return.hv)
    return(list(betaValues, hvlist))
  else
    return(betaValues)
}


# diversity function ############################################################################################ 
all.diversity<-function(x,traits){
  
  #bandwidth estimation based on first year
  comm=x
  trait=traits
  subComm <- round(comm[1,],2)*100 ## Selecting the first community
  subTrait <- trait[comm[1,]>0,] ## Selecting trait values of the community
  subComm <- subTrait[rep(1:nrow(subTrait), times = subComm[comm[1,]>0]), ] ## Replicating each trait combination times the occupancy of each species
  
  #estimate bandwidth using silverman method
  b=estimate_bandwidth(subComm)
  
  #alpha diversity measures
  richness<-kernel.alpha.a(round(x[c(1,6,11,16,21,26,31,36,41,46),],2)*100,traits,return.hv = T,abund = T,kde.bandwidth=b) # richness
  dispersion<-kernel.dispersion(richness[[2]],frac=1)#dispersion
  
  #similarity measures
  similarity<-kernel.beta.a(richness[[2]])#similarity measures

  
  #list of output
  list(richness[[1]],dispersion,similarity$Btotal)
}

##################################################################################################################
################################################################################################################## 
# input service
service="PEST"

if(service=="AQUA"){
  n="AQUA"
      OCC<- readRDS("AQUA_L.rds")
      ET<-readRDS("Aqua_pco_et.rds")
      }else if(service=="POLL"){
  n="POLL"
      OCC<- readRDS("POLL_L.rds")
      ET<-readRDS("Poll_pco_et.rds")
      }else if(service=="PEST"){
  n="PEST"
      OCC<- readRDS("PEST_L.rds")
      ET<-readRDS("Pest_pco_et.rds")
      }else{
  n="PECO"
      OCC<- readRDS("PECO_L.rds")
      ET<-readRDS("Peco_pco_et.rds")
      }

###################################################################################################################
# calculate effects trait diversity
all_et <- all.diversity(t(OCC[[i]]),ET)
all_et

# randomise traits across species
# reorder rows
ran_et<-ET
ran_et<- ran_et[sample(nrow(ran_et)),]

# makes sure names are correct 
rownames(ran_et)[1:nrow(ran_et)]<-rownames(ET)

# calculate diversity
all_et_ran <- all.diversity(t(OCC[[i]]),ran_et)

# list of all diversity measures
out<-list(all_et,all_et_ran)


# output
bs <-paste0("DIV_",n,"_",i,".rds")

# save output
saveRDS(out,bs)

rm(list = ls()) 