# author Arran Greenop

rm(list = ls())
library(ade4)
library(adespatial)
library(ggplot2)
library(ggpubr)
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

# function to calculate LRR for taxonomic and functional divesity measures #################################################

LRR <- function(x, base.var=FALSE){
  # takes one of the diversity metric datasets and calcultes a log resopnse ratio
  # the data each year is expressed as the log of the ratio to the year 1 value
  
  # first define the denominator for the response ratio calculation
  # we have an option of including uncertainty (or variability) in the first year, defined by base.var
  # if we want base.var then the denominator is the full posterior distribution of the first year's data
  if(base.var) denom <- mean(x[1,]) else denom <- x[1,]
  
  # for each iteration we have a timeseries. Calculate the 
  lrr <- t(apply(x, 1, function(ts) log(ts/denom)))
}


# function to calculate diversity trends across years ######################################################################
# returns the mean and credible intervals for diversity estimate
# x is a matrix of diversity estimates (rows are years and columns iterations)

trend<-function(x){
  out<- data.frame (matrix (ncol=6,nrow = 10))
  colnames(out)<-c("Year","Mean","95_LB","95_UB","80_LB","80_UB")
  out[1:10,1]<- seq(1970,2015,by=5)
  out[1:10,2]<- apply(x,1,mean)   
  out[1:10,3]<- apply(x,1,quantile,probs = 0.025)
  out[1:10,4]<- apply(x,1,quantile,probs = 0.975)
  out[1:10,5]<- apply(x,1,quantile,probs = 0.10)
  out[1:10,6]<- apply(x,1,quantile,probs = 0.90)
  out}

# function to assess differences from null and produce summary of outputs for FD measures ##################################
# x = observed diversity matrix and y = null diversity matrix, base.var=T/F includes varaiton in year 1 for diversity measures
# sim =  T/F indicating whether or not its a similarity index

summary. <-function(x,y,base.var=T,sim=F){
  # copy raw diversity values
  x1=x
  
  # for similarity index
  if(sim){
    
    y=NULL
    obse <-trend(as.matrix(x)) # observed trend
  
    # return
    obse  
  }else{
    
    # for diversity trends
    for( i in 1:nrow(x)){
      x1[i,]  <- x[i,]-y[i,]} # loop through each year and subtract the null community
    
    #standardised trend 
    null <- trend(x1) # comparison to null trend
    
    lr<-LRR(x,base.var=base.var) # turn to a log response ratio
    obse <-trend(lr) # observed trend
    
    #return
    list(obse,null)
  }
  
} #function end

# function to extract the diversity measures from Jasmin output and calculate summary statistics and null model results ###
# x is a list of diversity measures produced by Diversity_measures code 
# occupancy is an array of occupancy estimates 
# base.var indicates should error of the first year be included

div_out <-function(x,occupancy,base.var=T){
  

  # output dataframes
  n=length(x) # number of rows in output dataframe
  
  # outputs matrices for diversity measures
  div<-replicate(3,matrix(ncol=n,nrow=10),simplify=F)
  names(div)<-c("richness","dispersion","similarity")
  
  # main diversity outputs
  et_div<-div # FD
  et_div_null<-div[-3] # FD null
  
  
  # occupancy
  oc_div<-replicate(1,matrix(ncol=n,nrow=10),simplify=F)
  names(oc_div)<-c("similarity")

  # similarity measures for occupancy
  beta<-function(x){
  B <-beta.div.comp(t(x)[c(1,6,11,16,21,26,31,36,41,46),], coef = "J", quant = TRUE, save.abc = FALSE)
  list(B$D)
  }
  
  B_occ<-apply(occupancy,2,beta)
  

  # populate all the diversity matrices with the outputs from jasmin
  for (i in 1:n){
    
    # OBSERVED ###########################################
    et_div$richness[,i] <- x[[i]][[1]][[1]]
    et_div$dispersion[,i] <- x[[i]][[1]][[2]]
    et_div$similarity[,i] <-as.matrix(x[[i]][[1]][[3]])[1,]

    # NULL ################################################
    et_div_null$richness[,i] <- x[[i]][[2]][[1]]
    et_div_null$dispersion[,i] <- x[[i]][[2]][[2]]
    
    # OCCUPANCY###########################################
    oc_div$similarity [,i]<-as.matrix(B_occ[[i]][[1]])[1,]
  }
  

  ####################################################
  # occupancy average
  occ<- apply(occupancy, c(2,3), mean)[,c(1,6,11,16,21,26,31,36,41,46)]
  
  # standardised trends for diversity measures
  et_rich<-summary.(et_div$richness,et_div_null$richness,base.var=T)
  et_disp<-summary.(et_div$dispersion,et_div_null$dispersion,base.var=T)
  et_tot<-summary.(1-et_div$similarity,y=NULL,base.var=F,sim=T)

  # raw occupancy output
  occ1<-occ
  
  # occupancy
  a<-LRR(t(occ),base.var = base.var) # turn to a log response ratio
  occ<-trend(a) # get summary for mean occupancy
  occ_tot<-trend(1-oc_div$similarity) # get summary for total beta
  
  # all raw data outputs
  raw_data<- list(et_div$richness,et_div$dispersion,et_div$similarity,
                  t(occ1),oc_div$similarity)
  
  # names
  names(raw_data)<-c("Effects_rich","Effects_disp","Effects_sim",
                     "Taxonomic_diversity","Taxonomic_similarity")
  
  # list with all summary trends and raw data ouput
  div<-list(et_rich,et_disp,et_tot,
            occ,occ_tot,raw_data) 
  
  # names
  names(div)<-list("Effects_rich","Effects_disp","Effects_simi",
                   "Taxonomic_div","Taxonomic_sim","Raw_data") 
  div
}

# diversity and similarity plot function - each metric plotted individually #################################################################
# FD intercept is set at 0 and comparison is LRR
# simi is similarity and no intercept is set and comparison is Jaccard
# rand is difference from null model and intercept is set 0 

plot_div<-function(x,Div="FD",title,subtitle,x.axis.texts,x.title.texts,color,y.axis.texts){
    
  library(ggplot2)
    # diversity measures ("FD")
    y1=0
    n1="LRR"
    
    # similarity
    if(Div=="simi"){
    y1=NULL
    n1="Similarity"  
    x=x[-1,]}
    
    # difference from null
    if(Div=="rand"){
      n1="Difference from null"}
    
    # figure for diversity measures
      # standardised effect size plot
      # trend plot
      fig<-ggplot(x)+geom_line(aes(y=Mean,x=Year),color=color)+
        geom_errorbar(aes(x=Year,ymin=`95_LB`, ymax=`95_UB`,width=0.6),color=color)+
        theme(axis.text.y = element_text(size=7),
              axis.text.x= x.axis.texts ,
              axis.title.x=x.title.texts, 
              axis.title.y = y.axis.texts,
              panel.grid.major = element_blank(), 
              panel.grid.minor = element_blank(),
              panel.background = element_blank(),
              legend.title=element_text(size=8), 
              legend.text=element_text(size=7),
              legend.key.size = unit(0.5,"line"),
              legend.position="none",
              plot.margin=grid::unit(c(0.5,0.5,0.5,0.5), "mm"),
              axis.line = element_line(colour = "black"),
              plot.title = element_text(face="bold",size=9),
              plot.subtitle=element_text(size=9))+
        geom_hline(yintercept =y1,linetype="dashed")+ylab(n1)+ggtitle(title,subtitle = subtitle)+
        geom_segment(aes(x=Year,xend=Year,y=`80_LB`, yend=`80_UB`),color=color, size = 2)+
        geom_point(aes(y=Mean,x=Year), size = 1)
  
  # list of plots    
  fig
  }


# OCCUPANCY ESTIMATES ##############################################################################################
########################################### POLLINATORS ############################################################
# list for species occupancy
POLL_occ<-readRDS("POLL_OCC.rds")

# reorder dataframe alphabetically
POLL_ALL <-sp_arr(POLL_occ,reg="GB")

######################################### AQUATIC FUNCTIONS ########################################################
# list for species occupancy
AQUA_occ<-readRDS("AQUA_OCC.rds")

# reorder dataframe alphabetically
AQUA_ALL <-sp_arr(AQUA_occ,reg="GB")


######################################### PEST CONTROL #############################################################
PECO_occ<-readRDS("PECO_OCC.rds")

# reorder dataframe alphabetically
PECO_ALL <-sp_arr(PECO_occ,reg="GB")

########################################### PESTS ##################################################################
# list for species occupancy
PEST_occ<-readRDS("PEST_OCC.rds")

# reorder dataframe alphabetically
PEST_ALL <-sp_arr(PEST_occ,reg="GB")


####################################################################################################################
# AQUATIC FUNCTIONS ################################################################################################
# all diversity estimates
out<-readRDS("AQUA_DIV_OUTPUTS.rds")

# diversity outputs
aq <-div_out(out,AQUA_ALL)


# observed diversity measures
# taxonomic
aq_oc<-plot_div(aq$Taxonomic_div,Div="FD",title="Aquatic functions",subtitle = "Taxonomic diversity", color="#3399FF",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                y.axis.texts = element_text(size=8))
# effects disp
aq_ef<-plot_div(aq$Effects_disp[[1]],Div="FD",title="",subtitle = "Functional diversity", color="#3399FF",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                y.axis.texts = element_blank())

# effects richness
aq_rief<-plot_div(aq$Effects_rich[[1]],Div="FD",title="Aquatic functions",subtitle = NULL, color="#3399FF",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                  y.axis.texts = element_text(size=8))

# taxo sim
aq_tx_sim<-plot_div(aq$Taxonomic_sim,Div="simi", title="Aquatic functions",subtitle ="Taxonomic similarity", color="#3399FF",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                                                                                                                            y.axis.texts = element_text(size=8))
# effects sim
aq_ef_sim<-plot_div(aq$Effects_simi,Div="simi", title="",subtitle = "Functional similarity", color="#3399FF",x.axis.texts = element_blank(),x.title.texts =element_blank(),
y.axis.texts = element_blank())

# differences between null models and observed results
# richness
aq_ef_ric_ra<-plot_div(aq$Effects_rich[[2]], Div="rand",title="",subtitle = "Functional richness", y.axis.texts = element_text(size=8), color="#3399FF",x.axis.texts = element_blank(),x.title.texts =element_blank())

# diversity
aq_ef_dis_ra<-plot_div(aq$Effects_disp[[2]], Div="rand",title="",subtitle = "Functional diversity",y.axis.texts = element_text(size=8), color="#3399FF",x.axis.texts =element_blank(),x.title.texts =element_blank())


# null results figure
aq_null<-ggarrange(aq_ef_dis_ra,aq_ef_ric_ra,ncol=2,nrow=1)

ggsave("EXT_FIG_2.png",plot=aq_null, dpi=600, dev='png',height=4.0, width=5.5, units="in")

# POLLINATORS ##########################################################################################
# all diversity estimates
out<-readRDS("POLL_DIV_OUTPUTS.rds")

# diversity outputs
po<-div_out(out,POLL_ALL)

# observed diversity measures
# taxonomic
po_oc<-plot_div(po$Taxonomic_div,Div="FD",title="Pollination",subtitle =NULL, color="#FF9900",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                y.axis.texts = element_text(size=8))
# effects disp
po_ef<-plot_div(po$Effects_disp[[1]],Div="FD",title="",subtitle = NULL, color="#FF9900",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                y.axis.texts = element_blank())

# effects rich
po_rief<-plot_div(po$Effects_rich[[1]],Div="FD",title="Pollination",subtitle = NULL, color="#FF9900",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                  y.axis.texts =element_text(size=8))

# taxo sim
po_tx_sim<-plot_div(po$Taxonomic_sim,Div="simi", title="Pollination",subtitle = NULL, color="#FF9900",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                    y.axis.texts = element_text(size=8))
# effects sim
po_ef_sim<-plot_div(po$Effects_simi,Div="simi", title="",subtitle = NULL, color="#FF9900",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                    y.axis.texts = element_blank())



# differences between null models and observed results
# richness
po_ef_ric_ra<-plot_div(po$Effects_rich[[2]], Div="rand",title="",subtitle = "Functional richness", y.axis.texts = element_text(size=8),color= "#FF9900",x.axis.texts = element_blank(),x.title.texts =element_blank())

# diversity
po_ef_dis_ra<-plot_div(po$Effects_disp[[2]], Div="rand",title="",subtitle = "Functional diversity", y.axis.texts = element_text(size=8),color= "#FF9900",x.axis.texts = element_blank(),x.title.texts =element_blank())

# null results figure
poll_null<-ggarrange(po_ef_dis_ra,po_ef_ric_ra,ncol=1,nrow=2)

ggsave("EXT_FIG_3.png",plot=poll_null, dpi=600, dev='png',height=4.0, width=5.5, units="in")

# PESTS ################################################################################################################
# all diversity estimates
out<-readRDS("PEST_DIV_OUTPUTS.rds")

# diversity outputs
pe <-div_out(out,PEST_ALL)

# observed diversity measures
# taxonomic
pe_oc<-plot_div(pe$Taxonomic_div,Div="FD",title="Pests",subtitle = NULL, color="#F8766D",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8),
                y.axis.texts = element_text(size=8))
# effects disp
pe_ef<-plot_div(pe$Effects_disp[[1]],Div="FD",title="",subtitle = NULL, color="#F8766D",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8),
                y.axis.texts = element_blank())

# effects rich
pe_rief<-plot_div(pe$Effects_rich[[1]],Div="FD",title="Pests",subtitle = NULL, color="#F8766D",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8),
                  y.axis.texts = element_text(size=8))

# taxo sim
pe_tx_sim<-plot_div(pe$Taxonomic_sim,Div="simi", title="Pests",subtitle =NULL, color="#F8766D",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8),
                    y.axis.texts = element_text(size=8))
# effects sim
pe_ef_sim<-plot_div(pe$Effects_simi,Div="simi", title="",subtitle = NULL, color="#F8766D",x.axis.texts =  element_text(size=7),x.title.texts =element_text(size=8),
                    y.axis.texts = element_blank())




# differences between null models and observed results
# richness
pe_ef_ric_ra<-plot_div(pe$Effects_rich[[2]], Div="rand",title="",subtitle = "Functional richness", y.axis.texts = element_text(size=8),color="#F8766D",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8))

# diversity
pe_ef_dis_ra<-plot_div(pe$Effects_disp[[2]], Div="rand",title="",subtitle = "Functional diversity", y.axis.texts = element_text(size=8),color="#F8766D",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8))

# null results figure
pest_null<-ggarrange(pe_ef_dis_ra,pe_ef_ric_ra,ncol=1,nrow=2)
ggsave("EXT_FIG_5.png",plot=pest_null, dpi=600, dev='png',height=4.0, width=5.5, units="in")

# PEST CONTROL ###########################################################################################
# all diversity estimates
out<-readRDS("PECO_DIV_OUTPUTS.rds")

# all diversity outputs
pc <-div_out(out,PECO_ALL)


# observed diversity measures
# taxonomic
pc_oc<-plot_div(pc$Taxonomic_div,Div="FD",title="Pest control",subtitle = NULL, color="#00BA38",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                y.axis.texts = element_text(size=8))
# effects disp
pc_ef<-plot_div(pc$Effects_disp[[1]],Div="FD",title="",subtitle = NULL, color="#00BA38",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                y.axis.texts = element_blank())

# effects rich
pc_rief<-plot_div(pc$Effects_rich[[1]],Div="FD",title="Pest control",subtitle = NULL, color="#00BA38",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                  y.axis.texts = element_text(size=8))


# taxo sim
pc_tx_sim<-plot_div(pc$Taxonomic_sim,Div="simi", title="Pest control",subtitle = NULL, color="#00BA38",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                    y.axis.texts = element_text(size=8))
# effects sim
pc_ef_sim<-plot_div(pc$Effects_simi,Div="simi", title="",subtitle =NULL, color="#00BA38",x.axis.texts = element_blank(),x.title.texts =element_blank(),
                    y.axis.texts = element_blank())
                   
# differences between null models and observed results
# richness
pc_ef_ric_ra<-plot_div(pc$Effects_rich[[2]], Div="rand",title="",subtitle = "Functional richness", y.axis.texts = element_text(size=8),color="#00BA38",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8))

# diversity
pc_ef_dis_ra<-plot_div(pc$Effects_disp[[2]], Div="rand",title="",subtitle = "Functional diversity",y.axis.texts = element_text(size=8), color="#00BA38",x.axis.texts = element_text(size=7),x.title.texts =element_text(size=8))

# null results figure
peco_null<-ggarrange(pc_ef_dis_ra,pc_ef_ric_ra, ncol=1,nrow=2)

ggsave("EXT_FIG_4.png",plot=peco_null, dpi=600, dev='png',height=4.0, width=5.5, units="in") 

# FIGURES ###################################################################################
# diversity figures #########################################################################
library(ggpubr)

# Figure 1
F1<-ggarrange(aq_oc,aq_ef,
              po_oc,po_ef,
              pc_oc,pc_ef,
              pe_oc,pe_ef,nrow=4,ncol=2,align = "v",heights = c(1.2,1,1,1.3))
F1
ggsave("DIV_TRENDS.png",plot=F1, dpi=600, dev='tiff',   height=4.0, width=5.5, units="in") 

# Figure 2
F2<-ggarrange(aq_tx_sim,aq_ef_sim, 
              po_tx_sim,po_ef_sim, 
              pc_tx_sim,pc_ef_sim, 
              pe_tx_sim,pe_ef_sim, nrow=4,ncol=2,align = "v",heights = c(1.2,1,1,1.3),
              widths=c(1,1))
F2
ggsave("SIM_TRENDS.png",plot=F2, dpi=600, dev='tiff',   height=4.0, width=5.5, units="in") 

# Extended data 1
F3<-ggarrange(aq_rief,
              po_rief,
              pc_rief,
              pe_rief,nrow=4,ncol=1,align = "v",heights = c(1,1,1,1.3))
F3
ggsave("EXT_FIG_1.png",plot=F3, dpi=600, dev='tiff',   height=4.0, width=5.5, units="in") 
F3