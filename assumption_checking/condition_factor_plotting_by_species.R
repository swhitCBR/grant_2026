library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)

# Load pre-built data from the pipeline
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
  list("tags"=tags_tagpro,
       "events"=events_tagpro,
       "nodes"=nodes_tagpro)

}

sub_data <- create_atlas_tagger_subsets_mod()
tagsDF <- sub_data$"tags"

# usually condition factor is 
# Nash, Richard & Valencia, A.H. & Geffen, Audrey. (2006). The origin of Fulton's condition factor - Setting the record straight. Fisheries. 31. 236-238. 


# function provided by Rich
cfactor=function(x){
  # estimate condition factor
  # based on Chelan & Douglas PUD definitions
  # x[1]:length, x[2]: weight
  x=x[c(x[,1]*x[,2])>0,]
  out=(10*(x[,2])^(1/3))/x[,1]
  return(out)
}


get_cond_factor=function(len,wt){
  x=data.frame(len,wt)
  out=(10*(x[,2])^(1/3))/x[,1]
  return(out)}

get_cond_factor_alt=function(len,wt){
  x=data.frame(len,wt)
  out=(wt/((len*0.1)^3))*100
  return(out)}

get_cond_factor(len = 180,wt=50)

get_cond_factor_alt(len = 180,wt=50)
# (50/((180*0.1)^3))*100

# 10* cube root length divided by length
hist(cfactor(tagsDF[,c("length","weight")]))
cfDF <- data.frame(tagsDF[,c("length","weight")],
                   cf=get_cond_factor(tagsDF$length,tagsDF$weight),
                   cf_alt=get_cond_factor_alt(tagsDF$length,tagsDF$weight))

conditionDF_w <- tags_raw |> group_by(tag_code,release_location,species) |> 
  mutate(condition=get_cond_factor(len=length,wt=weight),
         condition_alt=get_cond_factor_alt(len=length,wt=weight)) |> 
  select(tag_code,length,weight,condition,condition_alt,tag_group,species,release_location) |>
  mutate(group=paste(release_location,tag_group),
         species_code=ifelse(species %in% c("11H","11W"),"CHN","STH")) |>
  filter(is.finite(condition) & condition>0 & !is.na(condition)) 


# library(FSA)
# wsVal("Chinook Salmon")
# wsVal("Rainbow Trout",group="lentic")

lm1 <- lm(I(weight)^(1/3)~length,data=conditionDF_w)
lm2 <- lm(I(length^3)~weight,data=conditionDF_w)
plot(lm2)

lm1_ind <- which(rstudent(lm1)< -5 | rstudent(lm1)>5)
lm2_ind <- which(rstudent(lm2)< -5 | rstudent(lm2)>5)

rstudent(lm1)[lm1_ind]
rstudent(lm2)[lm2_ind]

a=conditionDF_w[rstudent(lm1)< -5 | rstudent(lm1)>5,]
b=conditionDF_w[rstudent(lm2)< -5 | rstudent(lm2)>5,]
setdiff(a$tag_code,b$tag_code)

# log transformed x and y
lm1_loglog <- lm(log(weight)~log(length),data=conditionDF_w)
plot(log(weight)~log(length),data=conditionDF_w)
lines(log(1:500),predict(lm1_loglog,newdata =data.frame(length=1:500) ),col=4)
plot(weight~length,data=conditionDF_w)
lines(1:500,exp(predict(lm1_loglog,newdata =data.frame(length=1:500) )),col=4)
points(conditionDF_w$length[flagged_ind],conditionDF_w$weight[flagged_ind],pch=16,col="red")
lines(100:300,predict(lm1,newdata = data.frame(length=100:300))^3,col=2)


plot(rstudent(lm1_loglog))
abline(h=c(-5,5),lty=3,col=2)
loglog_ind <- which(rstudent(lm1_loglog) < -5 | rstudent(lm1_loglog)>5)
loglog_tagflag <- data.frame(conditionDF_w[loglog_ind,],resid=rstudent(lm1_loglog)[loglog_ind])
summary(lm1_loglog)

plot(conditionDF_w$length,conditionDF_w$weight,ylab="Weight",xlab="Length")
points(conditionDF_w$length[flagged_ind],conditionDF_w$weight[flagged_ind],pch=16,col="red")



# plot(lm1_loglog)

head(rstandard(lm1))
# head(resid(lm1))
# replicating internally studentized residuals
head(resid(lm1)/(summary(lm1)$sigma*sqrt(1-hatvalues(lm1))))
head(resid(lm1)/(summary(lm1)$sigma))
summary(lm1)$sigma

# rstudent(lm1)
res_thrsh <- 5
flagged_ind <- which(rstandard(lm1)< -res_thrsh | rstandard(lm1)>res_thrsh)
flag_tagDF <- data.frame(conditionDF_w[flagged_ind,c("tag_code","condition","condition_alt")],
                         stud_resid=rstudent(lm1)[flagged_ind],
                         stan_resid=rstandard(lm1)[flagged_ind],
                         pred_wt=predict(lm1)[flagged_ind]^3)
summary(lm(I(weight)^(1/3)~length,data=conditionDF_w[-c(flagged_ind),]))$sigma


par(mfrow=c(3,2))
plot(conditionDF_w$length,conditionDF_w$weight,ylab="Weight",xlab="Length")


# standardized vs studentized residual
res_v <- rstandard(lm1)
# res_v <- rstudent(lm1)


points(conditionDF_w$length[flagged_ind],conditionDF_w$weight[flagged_ind],pch=16,col="red")
lines(100:300,predict(lm1,newdata = data.frame(length=100:300))^3,col=2)

plot(conditionDF_w$length,conditionDF_w$weight^(1/3),ylab="Weight^(1/3)",xlab="Length")
abline(lm1,col=2)
points(conditionDF_w$length[flagged_ind],conditionDF_w$weight[flagged_ind]^(1/3),pch=16,col="red")

plot(conditionDF_w$length,res_v,ylab="resid",xlab="Length")
abline(h=0,col=2)
abline(h=-res_thrsh,col=2,lty=3)
abline(h=res_thrsh,col=2,lty=3)
points(conditionDF_w$length[flagged_ind],res_v[flagged_ind],pch=16,col="red")

# proportion detected outside of that
# virtually zero tags are expected to be detected at 5 standard deviations 
sd_vals <- c(1,2,2.5,3,4,5)
prop_left <- round(sapply(sd_vals,function(x) {pnorm(x,lower.tail = F)*2}),6)
data.frame(
  sd_vals,
  prop_left,
  expect_tags=nrow(conditionDF_w)*prop_left)

# Q-Q plot
plot(lm1,2)
# excluded tags
exclu_tab_for_RAB <- tags_raw |> group_by(tag_code,release_location,species) |> 
  mutate(condition=get_cond_factor(len=length,wt=weight),
         condition_alt=get_cond_factor_alt(len=length,wt=weight)) |> 
  select(tag_code,length,weight,condition,condition_alt,tag_group,species,release_location,tag_status,fish_status) |>
  mutate(group=paste(release_location,tag_group),
         species_code=ifelse(species %in% c("11H","11W"),"CHN","STH")) |>
  filter(!is.finite(condition) | condition==0 | is.na(condition) | tag_code %in% c(flag_tagDF$tag_code)) |> #| condition>0.3 | (length>180 & weight<20) |(length<140 & weight>40)
         select(-group) |>
         mutate(flag_reason= ifelse(tag_code %in% c(flag_tagDF$tag_code),paste("abs(stan.resid) >",res_thrsh),"missing length or weight"),
                omitted= !(tag_code %in% c(flag_tagDF$tag_code)),
                stud_resid=flag_tagDF$stan_resid[match(tag_code,flag_tagDF$tag_code)],
                pred_wt=flag_tagDF$pred_wt[match(tag_code,flag_tagDF$tag_code)]
                ) |> arrange(!omitted) |> relocate(tag_code,omitted,flag_reason,species_code,tag_status,fish_status,release_location,length,weight,pred_wt,stud_resid,condition,condition_alt)
exclu_tab_for_RAB 


conditionDF_w[which.max(conditionDF_w$condition),]
conditionDF_w[which.min(conditionDF_w$condition),]

conditionDF_l <- conditionDF_w |> 
  pivot_longer(cols=c("length","weight","condition")) |>
  mutate(name = ifelse(name=="length","Length(mm)",ifelse(name=="weight","Weight(gm)","Condition Factor"))) |>
  mutate(name=factor(name,levels=c("Weight(gm)","Length(mm)","Condition Factor")))

grp_nms <- unique(conditionDF_l$group)
nice_labels=c(expression("a. Rock Island tailrace live fish" ~ (italic(R[1]))),
              expression("b. Priest Rapids tailrace live fish" ~ (italic(R[2]))),
              expression("c. Priest Rapids tailrace dead fish" ~ (italic(D[2]))))
nbins= 20


CHN_plt_ls <- list()
for(ii in 1:length(grp_nms)){
  CHN_plt_ls[[ii]]=ggplot() + 
    geom_histogram(
      data=conditionDF_l |> filter(value!=0 & group==grp_nms[ii] & species_code == "CHN") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill="cyan",color="black") +
    scale_y_continuous(labels = function(x) sprintf("%.2f", x),expand = expansion(mult = c(0.00, 0.25))) + 
    scale_x_continuous(expand = expansion(mult = c(0.1, 0.1))) +
    ggtitle(nice_labels[ii]) +
    facet_wrap(~name,scales="free",strip.position = "bottom" ) +#+  # scale_y_continuous(labels = scales::percent) 
    labs(y="Proportion") +
    # adding invisible full data set
    geom_histogram(
      data=conditionDF_l |> filter(value!=0 & species_code == "CHN") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill=NA,color=NA) +
    theme_bw() +
    theme( panel.grid = element_blank(),axis.title.x = element_blank()) +
    theme(strip.placement = "outside",axis.title.x = element_blank(),strip.background.x = element_blank())+
    theme(plot.title = element_text(hjust = 0),plot.title.position = "plot",axis.text = element_text(color="black"))
}

STH_plt_ls <- list()
for(ii in 1:length(grp_nms)){
  STH_plt_ls[[ii]]=ggplot() + 
    geom_histogram(
      data=conditionDF_l |> filter(value!=0 & group==grp_nms[ii] & species_code == "STH") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill="cyan",color="black") +
    scale_y_continuous(labels = function(x) sprintf("%.2f", x),expand = expansion(mult = c(0.00, 0.25))) + 
    scale_x_continuous(expand = expansion(mult = c(0.1, 0.1))) +
    ggtitle(nice_labels[ii]) +
    facet_wrap(~name,scales="free",strip.position = "bottom" ) +#+  # scale_y_continuous(labels = scales::percent) 
    labs(y="Proportion") +
    # adding invisible full data set
    geom_histogram(
      data=conditionDF_l |> filter(value!=0 & species_code == "STH") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill=NA,color=NA) +
    theme_bw() +
    theme( panel.grid = element_blank(),axis.title.x = element_blank()) +
    theme(strip.placement = "outside",axis.title.x = element_blank(),strip.background.x = element_blank())+
    theme(plot.title = element_text(hjust = 0),plot.title.position = "plot",axis.text = element_text(color="black"))
}

# CHN_cond_latt <- grid.arrange(CHN_plt_ls[[1]],CHN_plt_ls[[2]],CHN_plt_ls[[3]],ncol=1)
# STH_cond_latt <- grid.arrange(STH_plt_ls[[1]],STH_plt_ls[[2]],STH_plt_ls[[3]],ncol=1)

png("media/png/assumption_checking/CHN_condition_fig.png",units = "in",width=6.5,height=7,res=300)
grid.arrange(CHN_plt_ls[[1]],CHN_plt_ls[[2]],CHN_plt_ls[[3]],ncol=1)
dev.off()

png("media/png/assumption_checking/STH_condition_fig.png",units = "in",width=6.5,height=7,res=300)
grid.arrange(STH_plt_ls[[1]],STH_plt_ls[[2]],STH_plt_ls[[3]],ncol=1)
dev.off()

  


conditionDF_l_filt <- conditionDF_l |> filter(!tag_code %in% exclu_tab_for_RAB$tag_code)


CHN_plt_ls <- list()
for(ii in 1:length(grp_nms)){
  CHN_plt_ls[[ii]]=ggplot() + 
    geom_histogram(
      data=conditionDF_l_filt |> filter(value!=0 & group==grp_nms[ii] & species_code == "CHN") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill="cyan",color="black") +
    scale_y_continuous(labels = function(x) sprintf("%.2f", x),expand = expansion(mult = c(0.00, 0.25))) + 
    scale_x_continuous(expand = expansion(mult = c(0.1, 0.1))) +
    ggtitle(nice_labels[ii]) +
    facet_wrap(~name,scales="free",strip.position = "bottom" ) +#+  # scale_y_continuous(labels = scales::percent) 
    labs(y="Proportion") +
    # adding invisible full data set
    geom_histogram(
      data=conditionDF_l_filt |> filter(value!=0 & species_code == "CHN") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill=NA,color=NA) +
    theme_bw() +
    theme( panel.grid = element_blank(),axis.title.x = element_blank()) +
    theme(strip.placement = "outside",axis.title.x = element_blank(),strip.background.x = element_blank())+
    theme(plot.title = element_text(hjust = 0),plot.title.position = "plot",axis.text = element_text(color="black"))
}

STH_plt_ls <- list()
for(ii in 1:length(grp_nms)){
  STH_plt_ls[[ii]]=ggplot() + 
    geom_histogram(
      data=conditionDF_l_filt |> filter(value!=0 & group==grp_nms[ii] & species_code == "STH") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill="cyan",color="black") +
    scale_y_continuous(labels = function(x) sprintf("%.2f", x),expand = expansion(mult = c(0.00, 0.25))) + 
    scale_x_continuous(expand = expansion(mult = c(0.1, 0.1))) +
    ggtitle(nice_labels[ii]) +
    facet_wrap(~name,scales="free",strip.position = "bottom" ) +#+  # scale_y_continuous(labels = scales::percent) 
    labs(y="Proportion") +
    # adding invisible full data set
    geom_histogram(
      data=conditionDF_l_filt |> filter(value!=0 & species_code == "STH") ,
      aes(y=..count../sum(..count..),x=value),bins = nbins,fill=NA,color=NA) +
    theme_bw() +
    theme( panel.grid = element_blank(),axis.title.x = element_blank()) +
    theme(strip.placement = "outside",axis.title.x = element_blank(),strip.background.x = element_blank())+
    theme(plot.title = element_text(hjust = 0),plot.title.position = "plot",axis.text = element_text(color="black"))
}

# CHN_cond_latt <- grid.arrange(CHN_plt_ls[[1]],CHN_plt_ls[[2]],CHN_plt_ls[[3]],ncol=1)
# STH_cond_latt <- grid.arrange(STH_plt_ls[[1]],STH_plt_ls[[2]],STH_plt_ls[[3]],ncol=1)

png("media/png/assumption_checking/filt_CHN_condition_fig.png",units = "in",width=6.5,height=7,res=300)
grid.arrange(CHN_plt_ls[[1]],CHN_plt_ls[[2]],CHN_plt_ls[[3]],ncol=1)
dev.off()

png("media/png/assumption_checking/filt_STH_condition_fig.png",units = "in",width=6.5,height=7,res=300)
grid.arrange(STH_plt_ls[[1]],STH_plt_ls[[2]],STH_plt_ls[[3]],ncol=1)
dev.off()





conditionDF_l_alt_filt <- conditionDF_w |> 
  pivot_longer(cols=c("length","weight","condition_alt")) |>
  mutate(name = ifelse(name=="length","Length(mm)",ifelse(name=="weight","Weight(gm)","Condition Factor(alt)"))) |>
  mutate(name=factor(name,levels=c("Weight(gm)","Length(mm)","Condition Factor(alt)"))) |> 
  filter(!tag_code %in% exclu_tab_for_RAB$tag_code)
  
  
  CHN_plt_ls <- list()
  for(ii in 1:length(grp_nms)){
    CHN_plt_ls[[ii]]=ggplot() + 
      geom_histogram(
        data=conditionDF_l_alt_filt |> filter(value!=0 & group==grp_nms[ii] & species_code == "CHN") ,
        aes(y=..count../sum(..count..),x=value),bins = nbins,fill="cyan",color="black") +
      scale_y_continuous(labels = function(x) sprintf("%.2f", x),expand = expansion(mult = c(0.00, 0.25))) + 
      scale_x_continuous(expand = expansion(mult = c(0.1, 0.1))) +
      ggtitle(nice_labels[ii]) +
      facet_wrap(~name,scales="free",strip.position = "bottom" ) +#+  # scale_y_continuous(labels = scales::percent) 
      labs(y="Proportion") +
      # adding invisible full data set
      geom_histogram(
        data=conditionDF_l_alt_filt |> filter(value!=0 & species_code == "CHN") ,
        aes(y=..count../sum(..count..),x=value),bins = nbins,fill=NA,color=NA) +
      theme_bw() +
      theme( panel.grid = element_blank(),axis.title.x = element_blank()) +
      theme(strip.placement = "outside",axis.title.x = element_blank(),strip.background.x = element_blank())+
      theme(plot.title = element_text(hjust = 0),plot.title.position = "plot",axis.text = element_text(color="black"))
  }
  
  STH_plt_ls <- list()
  for(ii in 1:length(grp_nms)){
    STH_plt_ls[[ii]]=ggplot() + 
      geom_histogram(
        data=conditionDF_l_alt_filt |> filter(value!=0 & group==grp_nms[ii] & species_code == "STH") ,
        aes(y=..count../sum(..count..),x=value),bins = nbins,fill="cyan",color="black") +
      scale_y_continuous(labels = function(x) sprintf("%.2f", x),expand = expansion(mult = c(0.00, 0.25))) + 
      scale_x_continuous(expand = expansion(mult = c(0.1, 0.1))) +
      ggtitle(nice_labels[ii]) +
      facet_wrap(~name,scales="free",strip.position = "bottom" ) +#+  # scale_y_continuous(labels = scales::percent) 
      labs(y="Proportion") +
      # adding invisible full data set
      geom_histogram(
        data=conditionDF_l_alt_filt |> filter(value!=0 & species_code == "STH") ,
        aes(y=..count../sum(..count..),x=value),bins = nbins,fill=NA,color=NA) +
      theme_bw() +
      theme( panel.grid = element_blank(),axis.title.x = element_blank()) +
      theme(strip.placement = "outside",axis.title.x = element_blank(),strip.background.x = element_blank())+
      theme(plot.title = element_text(hjust = 0),plot.title.position = "plot",axis.text = element_text(color="black"))
  }
  
  # CHN_cond_latt <- grid.arrange(CHN_plt_ls[[1]],CHN_plt_ls[[2]],CHN_plt_ls[[3]],ncol=1)
  # STH_cond_latt <- grid.arrange(STH_plt_ls[[1]],STH_plt_ls[[2]],STH_plt_ls[[3]],ncol=1)
  
  png("media/png/assumption_checking/filt_CHN_condition_fig_filt_alt.png",units = "in",width=6.5,height=7,res=300)
  grid.arrange(CHN_plt_ls[[1]],CHN_plt_ls[[2]],CHN_plt_ls[[3]],ncol=1)
  dev.off()
  
  png("media/png/assumption_checking/filt_STH_condition_fig_filt_alt.png",units = "in",width=6.5,height=7,res=300)
  grid.arrange(STH_plt_ls[[1]],STH_plt_ls[[2]],STH_plt_ls[[3]],ncol=1)
  dev.off()
  
