
#' Function: add_DH_qsec3_elwise
#'
#' Generates Quarto code block for a detection history table filtered by species and status
add_DH_qsec3_elwise <- function(tag_DH_ls_nm_in = "raw_RI_summ",
                                header_in,
                                spp_in,
                                status_in,
                                header_level,
                                status_is = TRUE) {
  c(
    paste(header_level, header_in),
    "```{r,echo=F,eval=T}",
    if(status_is) {
      paste0("knitr::kable(tag_DH_ls$'", tag_DH_ls_nm_in, "' |> filter(spp=='", spp_in, "' & status=='", status_in, "'))")
    } else {
      paste0("knitr::kable(tag_DH_ls$'", tag_DH_ls_nm_in, "' |> filter(spp=='", spp_in, "' & status!='", status_in, "'))")
    },
    "```"
  )
}
