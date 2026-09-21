#' Extract Detection History by Tagger
#'
#' Retrieves capture history patterns (detection histories) for a specific 
#' species and release location across individual tagger groups.
#'
#' @param atlas_results_in List returned from \code{scrape_atlas_results()}
#' @param spp Character. Species code: "CHN" (Chinook) or "STH" (Steelhead)
#' @param release Character. Release location: "RI" (Rock Island) or "PR" (Priest Rapids)
#'
#' @return Invisibly returns a list of capture history patterns across taggers
#'
#' @details
#' Extracts and displays detection history data (capture patterns) for taggers A, B, and C
#' for the specified species and release location combination.
#'
#' @keywords assumption_check
#' @export
#' @examples
#' \dontrun{
#' atlas_results <- scrape_atlas_results("assumption_checking/BRZsel_run")
#' get_DH_tab_by_tagger(atlas_results, spp = "CHN", release = "RI")
#' }

get_DH_tab_by_tagger <- function(atlas_results_in=all_sites_atlas_results,spp,release){

  if(spp=="CHN"){
  if(release=="PR"){
    ragged_list<- list(
    apply(atlas_results_in$capture_history$`PR_Chinook_TAGGER A`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Chinook_TAGGER B`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Chinook_TAGGER C`$data,1,paste,collapse=" "))

    tot_tags <- c(
      atlas_results_in$capture_history$`PR_Chinook_TAGGER A`$total_fish,
      atlas_results_in$capture_history$`PR_Chinook_TAGGER B`$total_fish,
      atlas_results_in$capture_history$`PR_Chinook_TAGGER C`$total_fish
    )
  }
  
  if(release=="RI"){
  ragged_list<- list(
  apply(atlas_results_in$capture_history$`RI_Chinook_TAGGER A`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Chinook_TAGGER B`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Chinook_TAGGER C`$data,1,paste,collapse=" "))
        tot_tags <- c(
              atlas_results_in$capture_history$`RI_Chinook_TAGGER A`$total_fish,
              atlas_results_in$capture_history$`RI_Chinook_TAGGER B`$total_fish,
              atlas_results_in$capture_history$`RI_Chinook_TAGGER C`$total_fish  
        )
  }
  }

    if(spp=="STH"){
  if(release=="PR"){
    ragged_list<- list(
    apply(atlas_results_in$capture_history$`PR_Steelhead_TAGGER A`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Steelhead_TAGGER B`$data,1,paste,collapse=" "),
    apply(atlas_results_in$capture_history$`PR_Steelhead_TAGGER C`$data,1,paste,collapse=" "))
    tot_tags <- c(
      atlas_results_in$capture_history$`PR_Steelhead_TAGGER A`$total_fish,
      atlas_results_in$capture_history$`PR_Steelhead_TAGGER B`$total_fish,
      atlas_results_in$capture_history$`PR_Steelhead_TAGGER C`$total_fish
    )
  }
  
  if(release=="RI"){
  ragged_list<- list(
  apply(atlas_results_in$capture_history$`RI_Steelhead_TAGGER A`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Steelhead_TAGGER B`$data,1,paste,collapse=" "),
  apply(atlas_results_in$capture_history$`RI_Steelhead_TAGGER C`$data,1,paste,collapse=" "))
         tot_tags <- c(
      atlas_results_in$capture_history$`RI_Steelhead_TAGGER A`$total_fish,
      atlas_results_in$capture_history$`RI_Steelhead_TAGGER B`$total_fish,
      atlas_results_in$capture_history$`RI_Steelhead_TAGGER C`$total_fish
    )
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
  paste("Total: ",tot_tags)
)

  }
