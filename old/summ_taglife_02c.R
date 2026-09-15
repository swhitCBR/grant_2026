library(dplyr)
csv_fl_ls <- readRDS("csv_fl_ls.rds")

tl_dat <- csv_fl_ls$GPUD2026_taglife_12Aug2026

# install.packages( "C:/repos/pkgs/failCompare_1.1.0.tar.gz")
# devtools::load_all("../repos/pkgs/failCompare")

library(failCompare)

km_mod <- failCompare:::fc_fit(time = tl_dat$days_difference,model="all")
plot(km_mod)


hist(tl_dat$days_difference)
