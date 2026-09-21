get_DH_tab_by_tagger_MOD <- function(atlas_results_in=all_sites_atlas_results,spp,release){

  if(spp=="CHN"){
  if(release=="PR"){
    ragged_list<- list(
    apply(atlas_results_in$capture_history$`PR_Chinook_TAGGER A`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Chinook_TAGGER B`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Chinook_TAGGER C`$data,1,paste,collapse=" "))
  }
  
  if(release=="RI"){
  ragged_list<- list(
  apply(atlas_results_in$capture_history$`RI_Chinook_TAGGER A`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Chinook_TAGGER B`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Chinook_TAGGER C`$data,1,paste,collapse=" "))
  }
  }

    if(spp=="STH"){
  if(release=="PR"){
    ragged_list<- list(
    apply(atlas_results_in$capture_history$`PR_Steelhead_TAGGER A`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Steelhead_TAGGER B`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Steelhead_TAGGER C`$data,1,paste,collapse=" "))
  }
  
  if(release=="RI"){
  ragged_list<- list(
  apply(atlas_results_in$capture_history$`RI_Steelhead_TAGGER A`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Steelhead_TAGGER B`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Steelhead_TAGGER C`$data,1,paste,collapse=" "))
  }
  }

# Find the maximum length
max_len <- max(sapply(ragged_list, length))
# Pad shorter vectors with NA
padded_list <- lapply(ragged_list, function(x) {
  length(x) <- max_len
  x})
result_matrix <- do.call(cbind, padded_list)

rbind(
  paste("SPP:",spp,";","release:",release),
  c("Tagger A","Tagger B","Tagger C"),
  result_matrix,
  paste("Total: ",c(
  atlas_results_in$capture_history$`PR_Chinook_TAGGER A`$total_fish,
  atlas_results_in$capture_history$`PR_Chinook_TAGGER B`$total_fish,
  atlas_results_in$capture_history$`PR_Chinook_TAGGER C`$total_fish)
)
)

  }
