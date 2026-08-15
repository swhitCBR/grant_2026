
library(dplyr)

getwd()
dir("GrantPUD_2026_data")

csv_fl_nms <- dir("GrantPUD_2026_data",pattern=".csv")

csv_fl_ls <- lapply(csv_fl_nms,function(x) {csv_fl=read.csv(file.path("GrantPUD_2026_data",x))})
names(csv_fl_ls) <- sapply(csv_fl_nms,function(x){strsplit(x,"[.]")[[1]][1]})
names(csv_fl_ls)

# saveRDS(csv_fl_ls,"csv_fl_ls.rds")

tags_dat <- csv_fl_ls$GPUD2026_tags_12Aug2026
events_dat <- csv_fl_ls$GPUD2026_events_12Aug2026


# basic checks
# 3496 tags
# no NAs all unique
table(is.na(tags_dat$tag_code))

table(tags_dat$release_location)
table(tags_dat$tag_group)
table(tags_dat$tagger)
table(tags_dat$species)
table(tags_dat$survival_use)

# release dates 
table(tags_dat$tag_release_date)

tags_dat$spp_code=substr(tags_dat$species,start = 1,stop = 2)
tags_dat$reartype=substr(tags_dat$species,start = 3,stop = 3)

# 
table(tags_dat$survival_use,tags_dat$fish_status)


# creating a unique replicate code by "species" (spp_code and reartype), release date, and release location
tags_dat$replicate_code <- paste(tags_dat$species,tags_dat$tag_release_date,tags_dat$release_location,sep="_")
rep_codes <- unique(tags_dat$replicate_code)
repID_tab <- data.frame(repID=1:length(rep_codes),replicate_code=rep_codes)
tags_dat <- tags_dat |> left_join(repID_tab)

tags_dat_useT <- tags_dat |> 
  filter(survival_use==TRUE)

tags_dat_useT_summ <- tags_dat_useT |>  
  group_by(species,project_code,tag_group,tagger,release_location) |>
  summarize(n_tags=length(unique(tag_code)))

tags_dat_useF <- tags_dat |> 
  filter(survival_use==FALSE)

tags_dat_useF_summ <- tags_dat_useF |>  
  group_by(species,project_code,tag_group,tagger,release_location,repID) |>
  summarize(n_tags=length(unique(tag_code)))

# Tarmac fish
tarmac_tag_tab<- tags_dat |> filter(fish_status=="Tarmac") |> select(species,tag_release_date,release_location,repID,tag_code)


tags_dat_useF_summ <- tags_dat_useF |>  
  group_by(species,project_code,tag_group,tagger,release_location) |>
  summarize(n_tags=length(unique(tag_code)))




table(table(tags_dat$tag_code))






# View(csv_fl_ls$GPUD2026_events_12Aug2026)
# View(csv_fl_ls$GPUD2026_taglife_12Aug2026)
