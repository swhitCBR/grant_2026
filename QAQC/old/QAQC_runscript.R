setwd("C:/repos/grant_2026/QAQC")
# setwd("QAQC")

library(dplyr)

source("01_load_csvs.R")


rm(list=ls())


source("02_assign_repIDs_to_tags.R")

rm(list=ls())


source("03_generate_conting_tbs.R")

rm(list=ls())

source("04_tagger_rel_loc_repID_summ.R")


rm(list=ls())

source("05_DH_repID_summ_tbs.R")

library(quarto)

quarto_render("SW_QAQC_summ_tabs_1_of_2.qmd")
quarto_render("SW_QAQC_summ_tabs_2_of_2.qmd")



# system('start "" "SW_QAQC_summ_tabs_1_of_2.docx"')
# system('shell.execute("SW_QAQC_summ_tabs_1_of_2.docx")')
# install.packages("officer")
# library(officer)
# read_docx(path = "SW_QAQC_summ_tabs_1_of_2.docx")
# shell("start winword")

shell.exec("SW_QAQC_summ_tabs_1_of_2.docx")
shell.exec("SW_QAQC_summ_tabs_2_of_2.docx")

