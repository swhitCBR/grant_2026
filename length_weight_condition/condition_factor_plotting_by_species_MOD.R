library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)

# ============================================================
# Setup & Data Loading
# ============================================================
# Condition factor reference:
# Nash, Valencia & Geffen (2006). The origin of Fulton's condition
# factor - Setting the record straight. Fisheries. 31. 236-238.

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
tag_subsets_ls <- readRDS("data/clean/tag_subsets_ls.rds")
tags_raw <- csv_fl_ls$GPUD2026_tags_17Aug2026

create_atlas_tagger_subsets_mod <- function(atlas_file_path,
                                        tags_file = "data/clean/pre_tagpro/tags.csv",
                                        events_file = "data/clean/pre_tagpro/events.csv",
                                        nodes_file = "data/clean/pre_tagpro/nodes.csv") {
  tags_tagpro <- read.csv(tags_file, stringsAsFactors = FALSE)
  events_tagpro <- read.csv(events_file, stringsAsFactors = FALSE)
  nodes_tagpro <- read.csv(nodes_file, stringsAsFactors = FALSE)
  list("tags" = tags_tagpro, "events" = events_tagpro, "nodes" = nodes_tagpro)
}

sub_data <- create_atlas_tagger_subsets_mod()
tagsDF <- sub_data$"tags"

# ============================================================
# Condition Factor Calculation
# ============================================================
# Chelan & Douglas PUD definitions (Fulton's K and an alternate form)

get_cond_factor <- function(len, wt) {
  x <- data.frame(len, wt)
  (10 * (x[, 2])^(1 / 3)) / x[, 1]
}

get_cond_factor_alt <- function(len, wt) {
  x <- data.frame(len, wt)
  (wt / ((len * 0.1)^3)) * 100
}

# https://cdnsciencepub.com/doi/full/10.1139/F10-080
get_cond_factor_alt2 <- function(len, wt) {
  x <- data.frame(len, wt)
  (wt / ((len)^3)) * 100000
}


conditionDF_w <- tags_raw |>
  group_by(tag_code, release_location, species) |>
  mutate(condition = get_cond_factor(len = length, wt = weight),
         condition_alt = get_cond_factor_alt(len = length, wt = weight),
         condition_alt2 = get_cond_factor_alt2(len = length, wt = weight)) |>
  select(tag_code, length, weight, condition, condition_alt,condition_alt2, tag_group, species, release_location) |>
  mutate(group = paste(release_location, tag_group),
         species_code = ifelse(species %in% c("11H", "11W"), "CHN", "STH")) |>
  filter(is.finite(condition) & condition > 0 & !is.na(condition))
conditionDF_w


# ============================================================
# Outlier Detection (Length-Weight Regression)
# ============================================================
# weight^(1/3) ~ length; flag tags with standardized residuals
# beyond +/- res_thrsh (virtually no tags expected past 5 SD)
# lm0 <- lm(I(weight)^(1 / 3) ~ 1, data = conditionDF_w)
# plot(lm0)

lm1 <- lm(I(weight)^(1 / 3) ~ length, data = conditionDF_w)
lm2 <- lm(I(length^3)~weight,data=conditionDF_w)
lm1_loglog <- lm(log(weight)~log(length),data=conditionDF_w)
lm1_loglog_spp <- lm(log(weight)~0+log(length)* species_code,data=conditionDF_w)



# filtering based on "Standardized residuals"
res_thrsh <- 5
flagged_ind <- which(rstandard(lm1) < -res_thrsh | rstandard(lm1) > res_thrsh)
flag_tagDF <- data.frame(conditionDF_w[flagged_ind, c("tag_code", "condition", "condition_alt")],
                         stud_resid = rstudent(lm1)[flagged_ind],
                         stan_resid = rstandard(lm1)[flagged_ind],
                         pred_wt = predict(lm1)[flagged_ind]^3)



png("media/png/assumption_checking/outliers_in_condition.png",width = 6.5, height = 7, res = 300,units="in")
par(mfrow=c(3,2))
hist(conditionDF_w$weight,main="",xlab="Weight")
hist(conditionDF_w$length,main="",xlab="Length")
plot(weight~length,data=conditionDF_w)
lines(1:500,predict(lm1,newdata =data.frame(length=1:500))^3,col=2)
points(conditionDF_w$length[flagged_ind],conditionDF_w$weight[flagged_ind],pch=16,col="red")
lines(100:300,predict(lm1,newdata = data.frame(length=100:300))^3,col=2)
plot(conditionDF_w$length,conditionDF_w$weight^(1/3),ylab=expression(sqrt(Weight, 3)),xlab="Length")
abline(lm1,col=2)
points(conditionDF_w$length[flagged_ind],conditionDF_w$weight[flagged_ind]^(1/3),pch=16,col="red")

plot(conditionDF_w$length,conditionDF_w$weight-predict(lm1)^3,ylab="Resid.",xlab="Length")
abline(h=0,col=2)
points(conditionDF_w$length[flagged_ind],(conditionDF_w$weight-predict(lm1)^3)[flagged_ind],pch=16,col="red")
res_v <- rstandard(lm1)
plot(conditionDF_w$length,res_v,ylab="Stan. Resid.",xlab="Length")
points(conditionDF_w$length[flagged_ind],res_v[flagged_ind],pch=16,col="red")
abline(h=0,col=2)
abline(h=-res_thrsh,col=2,lty=3)
abline(h=res_thrsh,col=2,lty=3)
points(conditionDF_w$length[flagged_ind],res_v[flagged_ind],pch=16,col="red")
dev.off()



# ============================================================
# Exclusion Table
# ============================================================

exclu_tab_for_RAB <- tags_raw |>
  group_by(tag_code, release_location, species) |>
  mutate(condition = get_cond_factor(len = length, wt = weight),
         condition_alt = get_cond_factor_alt(len = length, wt = weight)) |>
  select(tag_code, length, weight, condition, condition_alt, tag_group, species,
         release_location, tag_status, fish_status) |>
  mutate(group = paste(release_location, tag_group),
         species_code = ifelse(species %in% c("11H", "11W"), "CHN", "STH")) |>
  filter(!is.finite(condition) | condition == 0 | is.na(condition) | tag_code %in% c(flag_tagDF$tag_code)) |>
  select(-group) |>
  mutate(flag_reason = ifelse(tag_code %in% c(flag_tagDF$tag_code),
                               paste("abs(stan.resid) >", res_thrsh),
                               "missing length or weight"),
         omitted = !(tag_code %in% c(flag_tagDF$tag_code)),
         stud_resid = flag_tagDF$stan_resid[match(tag_code, flag_tagDF$tag_code)],
         pred_wt = flag_tagDF$pred_wt[match(tag_code, flag_tagDF$tag_code)]) |>
  arrange(!omitted) |>
  relocate(tag_code, omitted, flag_reason, species_code, tag_status, fish_status,
           release_location, length, weight, pred_wt, stud_resid, condition, condition_alt)

exclu_tab_for_RAB

write.csv(exclu_tab_for_RAB,"media/png/assumption_checking/exclu_tab_for_RAB.csv",row.names = F)

# ============================================================
# Reshape for Plotting
# ============================================================

conditionDF_w_for_plot <- conditionDF_w |> filter(tag_code %in% tag_subsets_ls$"tags_SURVUSE_OR_EUTH_&_ACTIVE"$tag_code)
# 
# length(unique(tag_subsets_ls$"tags_SURVUSE_OR_EUTH_&_ACTIVE"$tag_code))


conditionDF_l <- conditionDF_w |>
  pivot_longer(cols = c("length", "weight", "condition")) |>
  mutate(name = ifelse(name == "length", "Length(mm)",
                 ifelse(name == "weight", "Weight(gm)", "Condition Factor")),
         name = factor(name, levels = c("Weight(gm)", "Length(mm)", "Condition Factor")))

conditionDF_l_filt <- conditionDF_l |> filter(!tag_code %in% exclu_tab_for_RAB$tag_code)

conditionDF_l_alt <- conditionDF_w |>
  pivot_longer(cols = c("length", "weight", "condition_alt")) |>
  mutate(name = ifelse(name == "length", "Length(mm)",
                 ifelse(name == "weight", "Weight(gm)", "Condition Factor(alt)")),
         name = factor(name, levels = c("Weight(gm)", "Length(mm)", "Condition Factor(alt)"))) 
  
conditionDF_l_alt_filt <- conditionDF_l_alt |>   filter(!tag_code %in% exclu_tab_for_RAB$tag_code)

# ============================================================
# Plotting Helpers
# ============================================================

grp_nms <- unique(conditionDF_l$group)
nice_labels <- c(expression("a. Rock Island tailrace live fish" ~ (italic(R[1]))),
                  expression("b. Priest Rapids tailrace live fish" ~ (italic(R[2]))),
                  expression("c. Priest Rapids tailrace dead fish" ~ (italic(D[2]))))
nbins <- 20

# Build the 3-panel (by release group) histogram list for one species
make_species_plots <- function(data_long, sp_code) {
  lapply(seq_along(grp_nms), function(ii) {
    ggplot() +
      geom_histogram(
        data = data_long |> filter(value != 0 & group == grp_nms[ii] & species_code == sp_code),
        aes(y = ..count.. / sum(..count..), x = value), bins = nbins, fill = "cyan", color = "black") +
      scale_y_continuous(labels = function(x) sprintf("%.2f", x), expand = expansion(mult = c(0.00, 0.25))) +
      scale_x_continuous(expand = expansion(mult = c(0.1, 0.1))) +
      ggtitle(nice_labels[ii]) +
      facet_wrap(~name, scales = "free", strip.position = "bottom") +
      labs(y = "Proportion") +
      # invisible full data set, to fix facet scales across groups
      geom_histogram(
        data = data_long |> filter(value != 0 & species_code == sp_code),
        aes(y = ..count.. / sum(..count..), x = value), bins = nbins, fill = NA, color = NA) +
      theme_bw() +
      theme(panel.grid = element_blank(), axis.title.x = element_blank()) +
      theme(strip.placement = "outside", axis.title.x = element_blank(), strip.background.x = element_blank()) +
      theme(plot.title = element_text(hjust = 0), plot.title.position = "plot", axis.text = element_text(color = "black"))
  })
}

save_species_panel <- function(plt_ls, filepath) {
  png(filepath, units = "in", width = 6.5, height = 7, res = 300)
  grid.arrange(plt_ls[[1]], plt_ls[[2]], plt_ls[[3]], ncol = 1)
  dev.off()
}

# ============================================================
# Figures: Unfiltered
# ============================================================

save_species_panel(make_species_plots(conditionDF_l, "CHN"),
                    "media/png/assumption_checking/CHN_condition_fig1a.png")
save_species_panel(make_species_plots(conditionDF_l, "STH"),
                    "media/png/assumption_checking/STH_condition_fig2a.png")

# ============================================================
# Figures: Filtered (flagged/missing tags removed), condition
# ============================================================

save_species_panel(make_species_plots(conditionDF_l_filt, "CHN"),
                    "media/png/assumption_checking/CHN_condition_fig1b_filt.png")
save_species_panel(make_species_plots(conditionDF_l_filt, "STH"),
                    "media/png/assumption_checking/STH_condition_fig2b_filt.png")

# ===============================================================================================
# Figures: Alternative Fulton-based condition (flagged/missing tags removed), condition
# ===============================================================================================

save_species_panel(make_species_plots(conditionDF_l_alt, "CHN"),
                   "media/png/assumption_checking/CHN_condition_fig1c_alt.png")
save_species_panel(make_species_plots(conditionDF_l_alt, "STH"),
                   "media/png/assumption_checking/STH_condition_fig2c_alt.png")

# ============================================================
# Figures: Filtered, alternate condition factor
# ============================================================

save_species_panel(make_species_plots(conditionDF_l_alt_filt, "CHN"),
                    "media/png/assumption_checking/CHN_condition_fig1d_alt_filt.png")
save_species_panel(make_species_plots(conditionDF_l_alt_filt, "STH"),
                    "media/png/assumption_checking/STH_condition_fig2d_alt_filt.png")

