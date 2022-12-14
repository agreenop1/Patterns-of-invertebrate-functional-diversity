# README

R code files

Trait_processing – This script was used to turn the raw traits into synthetic traits using principle coordinate analysis and needs to be run first. It also transforms the occupancies into a list format that was used to calculate the diversity measures. Note, for aquatic functions and pollination the trait resolution columns needs to be removed before any analysis. 

Diversity_calculations – This script was used to calculate all the diversity measures used in the manuscript. Be aware of very long computing times (several hours to days) if this script is run on a single core (ideally needs to be run on a high performance computing cluster). Much of the code utilised in this script is based on code in the BAT and hypervolume packages (Cardoso et al., 2015; Blonder, 2018; Mammola & Cardoso, 2020). 

Paper_outputs – This script was used to process and calculate summary statistics for all the diversity trends. It also includes code to produce the figures found in the manuscript.

All files and data are at https://zenodo.org/record/5101130#.YvO4wXbMJPY.
Any questions please email: arrgre@ceh.ac.uk


References
Blonder, B. (2018) Hypervolume: High dimensional geometry and set operations using kernel density estimation, support vector machines, and convex hulls.
Cardoso, P., Rigal, F. & Carvalho, J.C. (2015) BAT - Biodiversity Assessment Tools, an R package for the measurement and estimation of alpha and beta taxon, phylogenetic and functional diversity. Methods in Ecology and Evolution, 6, 232–236.
Mammola, S. & Cardoso, P. (2020) Functional diversity metrics using kernel density n ‐dimensional hypervolumes. Methods in Ecology and Evolution, 11, 986–995.

