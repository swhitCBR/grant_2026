
library(dplyr)

getwd()
dir("GrantPUD_2026_data")




csv_fl_nms <- dir("../data/Round 2",pattern=".csv")
csv_fl_ls <- lapply(csv_fl_nms,function(x) {csv_fl=read.csv(file.path("../data/Round 2",x))})


# csv_fl_nms <- dir("../GrantPUD_2026_data",pattern=".csv")
# csv_fl_ls <- lapply(csv_fl_nms,function(x) {csv_fl=read.csv(file.path("../GrantPUD_2026_data",x))})



names(csv_fl_ls) <- sapply(csv_fl_nms,function(x){strsplit(x,"[.]")[[1]][1]})
names(csv_fl_ls)

saveRDS(csv_fl_ls,"tmp_data/csv_fl_ls.rds")



# View(csv_fl_ls)

# csv_fl_ls$GPUD2026_tags_12Aug2026
