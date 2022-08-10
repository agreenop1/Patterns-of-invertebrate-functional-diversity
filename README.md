README
R code files
Trait_processing – This script was used to turn the raw traits into synthetic traits using principle coordinate analysis and needs to be run first. It also transforms the occupancies into a list format that was used to calculate the diversity measures. Note, for aquatic functions and pollination the trait resolution columns needs to be removed before any analysis. 
Diversity_calculations – This script was used to calculate all the diversity measures used in the manuscript. Be aware of very long computing times (several hours to days) if this script is run on a single core (ideally needs to be run on a high performance computing cluster). Much of the code utilised in this script is based on code in the BAT and hypervolume packages (Cardoso et al., 2015; Blonder, 2018; Mammola & Cardoso, 2020). 
Paper_outputs – This script was used to process and calculate summary statistics for all the diversity trends. It also includes code to produce the figures found in the manuscript.

Any questions please email: arrgre@ceh.ac.uk

Trait files
AQUA_ET – Aquatic functions effects traits (csv)
•	4 traits with each level split into individual columns with species affinity fuzzy coded
•	For 79 species the traits are at the genus level and 13 at the species level. This is indicated in trait_resolution column.
POLL_ET – Pollination effects traits (csv)
•	9 traits – either categorical or continuous. 
•	For some of the species time on flower, nectar foraging, pollen foraging, stigma contact and dry pollen on the body were assigned at genus level. This is indicated in trait_resolution column.
PECO_ET – Pest control effects traits (csv)
•	4 traits – continuous, categorical or binary
PEST_ET – Pest effects traits (csv)
•	3 traits – continuous or categorical

Synthetic trait files (PCoA axes)
Aqua_pco_et – Aquatic functions effects synthetic traits
Poll_pco_et – Pollinator effects synthetic traits
Peco_pco_et – Pest control effects synthetic traits 
Pest_pco_et – Pest effects synthetic traits 


Raw occupancy files
AQUA_OCC – Caddisfly species occupancies (rds) 
POLL_OCC – Pollinator species occupancies (rds)
PECO_OCC – Pest control species occupancies (rds)
PEST_OCC – Pest species occupancies (rds)

Compiled occupancy estimates in a list
AQUA_L – Caddisfly species occupancies (rds) 
POLL_L – Pollinator species occupancies (rds)
PECO_L – Pest control species occupancies (rds)
PEST_L – Pest species occupancies (rds)
Diversity measures
Lists of diversity measures for every iteration of occupancy estimates (1-1000)
AQUA_DIV – Aquatic functions (rds) 
POLL_DIV – Pollinators (rds)
PECO_DIV – Pest control (rds)
PEST_DIV – Pests (rds)



References
Blonder, B. (2018) Hypervolume: High dimensional geometry and set operations using kernel density estimation, support vector machines, and convex hulls.
Cardoso, P., Rigal, F. & Carvalho, J.C. (2015) BAT - Biodiversity Assessment Tools, an R package for the measurement and estimation of alpha and beta taxon, phylogenetic and functional diversity. Methods in Ecology and Evolution, 6, 232–236.
Mammola, S. & Cardoso, P. (2020) Functional diversity metrics using kernel density n ‐dimensional hypervolumes. Methods in Ecology and Evolution, 11, 986–995.

