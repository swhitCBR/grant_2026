# library(vitality)

csv_fl_ls <- readRDS("data/clean/csv_fl_ls.rds")
taglife_rawDF <- csv_fl_ls$GPUD2026_taglife_17Aug2026

# Extract failure times by lot
lot1_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 1"]
lot2_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 2"]
lot3_data <- taglife_rawDF$days_difference[taglife_rawDF$lot == "Lot 3"]
pooled_data <- taglife_rawDF$days_difference

# diverges after 4
n_rc_tags <- 3
lot1_weib2 <- failCompare::fc_fit(time = lot1_data,model="weibull",rc.value = tail(sort(lot1_data),n_rc_tags)[1])
lot1_weib2$par_tab["scale",1] * gamma(1 + 1/lot1_weib2$par_tab["shape",1])

tmp_lot1_weib2 <- list()
weib_means <- c()
for(ii in 1:10){
  tmp_lot1_weib2[[ii]] <- failCompare::fc_fit(time = lot1_data,model="weibull",rc.value = tail(sort(lot1_data),ii)[1])
  weib_means[ii] <- tmp_lot1_weib2[[ii]]$par_tab["scale",1] * gamma(1 + 1/tmp_lot1_weib2[[ii]]$par_tab["shape",1])
}

# 66.9825
ATLAS_means <- c(67.0521,67.1355,67.2373,67.3591,67.5003,67.6290,67.7718,67.9649,68.2307,68.3196)
weib_means

data.frame(n_tagsRC=1:10,ATLAS_means,weib_means)
# get_weib2_mean <-function(
#   lot1_weib2$par_tab["scale",1] * gamma(1 + 1/lot1_weib2$par_tab["shape",1])



# taglife.fn=function(tags.in,plot.taglife=F){
#     answer <- optim(par=c(min(tags.in),.1,max(tags.in)),fn=logweib.lik,hessian=F,tags.in=tags.in)
#     answer <- optim(par=answer$par,fn=logweib.lik,method="BFGS",hessian=T,tags.in=tags.in)

#     out=data.frame(matrix(0,nrow=3,ncol=3))
#     out[,1]=c("Beta:", "Gamma:","Eta")
#     out[,2]=abs(answer$par)
#     out[,3]=apply(cbind("(",round(sqrt(diag(solve(answer$hessian))),4),")"),1,paste,collapse="")
#     names(out)=c("Parameter","Estimate","s.e.")
#     if(plot.taglife){
#     left=1-(1:length(tags.in))/length(tags.in)
#     par(mar=c(5,5,2,2),lab=c(10,10,7))    
#     plot(tags.in,left,xlab="Time (days) to failure",
#          ylab="Percent Tags Surviving",lwd=3,cex=1.2,pch=16,
#          xlim=c(0,max(tags.in)+6),ylim=c(0,1))
#     tag.pred=0:(round(max(tags.in))+5)
#     lines(tag.pred,fail.fn(tag.pred,out[1,2],out[2,2],out[3,2]),lwd=3,col=4)
#     mtext(paste(c("Mean Time to Failure = ",mttf(out[,2])),collapse=""),outer=F,line=.5)
#     }
 
    
#     return(out)
# }